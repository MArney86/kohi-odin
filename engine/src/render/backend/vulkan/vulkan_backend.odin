package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import strings "core:strings"
import runtime "base:runtime"
import logger "../../../core/logger"
import darray "../../../containers/darray"
vk_context : types.vulkan_context

initialize :: proc(backend: ^types.renderer_backend, application_name: string, plat_state: ^types.platform_state) -> bool {
    loaded := vk.initialize()
    if !loaded {
        return false
    }

    //TODO: custom allocator
    vk_context.allocator = nil

    app_info: vk.ApplicationInfo = {vk.StructureType.APPLICATION_INFO,nil,nil,0,nil,0,0}
    app_info.apiVersion = vk.API_VERSION_1_4
    app_info.pApplicationName = strings.clone_to_cstring(application_name)
    app_info.applicationVersion = vk.MAKE_VERSION(1, 0, 0)
    app_info.pEngineName = "Kohi Engine"
    app_info.engineVersion = vk.MAKE_VERSION(1, 0, 0)

    create_info: vk.InstanceCreateInfo = {vk.StructureType.INSTANCE_CREATE_INFO,nil,vk.InstanceCreateFlags(nil),nil,0,nil,0,nil}
    create_info.pApplicationInfo = &app_info
    required_extensions := cast(^[dynamic]cstring)darray.Make(cstring)
    temp : cstring = strings.clone_to_cstring(vk.KHR_SURFACE_EXTENSION_NAME)
    darray.push(cast(rawptr)required_extensions, cstring, &temp)
    get_required_extension_names(required_extensions)
    when ODIN_DEBUG {
        temp = strings.clone_to_cstring(vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
        darray.push(cast(rawptr)required_extensions, cstring, &temp)

        logger.DEBUG("Required Vulkan Extensions:")
        for i: int; i < len(required_extensions); i += 1 {
            logger.DEBUG("  %s", strings.clone_from_cstring(required_extensions[i]))
        }
    }
    create_info.enabledExtensionCount = cast(u32)len(required_extensions)
    create_info.ppEnabledExtensionNames = raw_data(required_extensions^)

    required_validation_layers : ^[dynamic]cstring = nil
    required_validation_count: u32 = 0

    when ODIN_DEBUG {
        required_validation_layers = cast(^[dynamic]cstring)darray.Make(cstring)
        defer darray.Delete(cast(rawptr)required_validation_layers, cstring)
        temp = "VK_LAYER_KHRONOS_validation"
        logger.INFO("Validation layers enabled. Enumerating...")
        darray.push(cast(rawptr)required_validation_layers, cstring, &temp)
        required_validation_count = cast(u32)len(required_validation_layers)

        available_layer_count: u32
        vk.CHECK(vk.EnumerateInstanceLayerProperties(&available_layer_count, nil))
        available_layers := cast(^[dynamic]vk.LayerProperties)darray.Make(vk.LayerProperties)
        defer darray.Delete(cast(rawptr)available_layers, vk.LayerProperties)
        darray.Reserve(cast(rawptr)available_layers, vk.LayerProperties, cast(u64)available_layer_count)
        vk.CHECK(vk.EnumerateInstanceLayerProperties(&available_layer_count, raw_data(available_layers^)))
        darray.set_len(cast(rawptr)available_layers, vk.LayerProperties, cast(u64)available_layer_count)

        //check availability of required layers
        for i:u32=0;i<required_validation_count;i+=1 {
            logger.INFO("Searching for layer: %s...", strings.clone_from_cstring(required_validation_layers[i]))
            found : b8 = false;
            for j:u32=0;j<available_layer_count;j+=1 {
                layer_name_cstr := cstring(&available_layers[j].layerName[0])
                layer_name := strings.clone_from_cstring(layer_name_cstr)
                if layer_name == strings.clone_from_cstring(required_validation_layers[i]) {
                    logger.INFO("Found required layer: %s", layer_name)
                    found = true
                    break
                }
            }
            
            if !found {
                logger.FATAL("Required validation layer not found: %s", strings.clone_from_cstring(required_validation_layers[i]))
                return false
            }
        }
        logger.INFO("All required validation layers found.")
    }

    create_info.enabledLayerCount = required_validation_count
    create_info.ppEnabledLayerNames = raw_data(required_validation_layers^)

    vk.CHECK(vk.CreateInstance(&create_info, vk_context.allocator, &vk_context.instance))
    logger.INFO("Vulkan renderer initialized successfully.")
    vk.load_proc_addresses_instance(vk_context.instance)
    when ODIN_DEBUG {
        logger.DEBUG("Creating Vulkan Debugger...")
        log_severity: vk.DebugUtilsMessageSeverityFlagsEXT = {.ERROR, .WARNING, .INFO} //._VERBOSE}
        message_type: vk.DebugUtilsMessageTypeFlagsEXT = {.GENERAL, .VALIDATION, .PERFORMANCE}
        debug_create_info: vk.DebugUtilsMessengerCreateInfoEXT = vk.DebugUtilsMessengerCreateInfoEXT{
            sType = vk.StructureType.DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            messageSeverity = log_severity,
            messageType = message_type,
            pfnUserCallback = vk_debug_callback,
            pUserData = nil,
        }
 

        vk.CHECK(vk.CreateDebugUtilsMessengerEXT(vk_context.instance, &debug_create_info, vk_context.allocator, &vk_context.debug_messenger))
        logger.DEBUG("Vulkan Debugger created.")
    }

    logger.DEBUG("Creating Vulkan surface...")
    if !create_vulkan_surface(plat_state, &vk_context) {
        logger.ERROR("Failed to create Vulkan surface.")
        return false
    }

    if !vulkan_device_create(&vk_context) {
        logger.ERROR("Failed to create Vulkan device.")
        return false
    }

    logger.INFO("Vulkan renderer initialized successfully.")
    return true
}

shutdown :: proc(backend: ^types.renderer_backend) {
        
    when ODIN_DEBUG {
        logger.DEBUG("Destroying Vulkan resources...")

        if vk_context.debug_messenger != vk.DebugUtilsMessengerEXT(0) {
            vk.DestroyDebugUtilsMessengerEXT(vk_context.instance, vk_context.debug_messenger, vk_context.allocator)
            vk_context.debug_messenger = vk.DebugUtilsMessengerEXT(0)
        }
    }
    logger.DEBUG("Destroying Vulkan instance...")
    if vk_context.instance != nil {
        vk.DestroyInstance(vk_context.instance, vk_context.allocator)
        vk_context.instance = nil
    }
    
    vk.close()
}

on_resized :: proc(backend: ^types.renderer_backend, width: u16, height: u16) {
    // Vulkan-specific resize handling code here
}

begin_frame :: proc(backend: ^types.renderer_backend, delta_time: f32) -> bool {
    // Vulkan-specific begin frame code here
    return true
}

end_frame :: proc(backend: ^types.renderer_backend, delta_time: f32) -> bool {
    // Vulkan-specific end frame code here
    return true
}

vk_debug_callback :: proc "system" (
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT, 
    message_type: vk.DebugUtilsMessageTypeFlagsEXT, 
    callback_data: ^vk.DebugUtilsMessengerCallbackDataEXT, 
    user_data: rawptr,
) -> b32 {
    context = runtime.default_context()
    
    if .ERROR in message_severity {
        logger.ERROR("[VULKAN]: %s", strings.clone_from_cstring(callback_data.pMessage))
    } else if .WARNING in message_severity {
        logger.WARN("[VULKAN]: %s", strings.clone_from_cstring(callback_data.pMessage))
    } else if .INFO in message_severity {
        logger.INFO("[VULKAN]: %s", strings.clone_from_cstring(callback_data.pMessage))
    } else if .VERBOSE in message_severity {
        logger.DEBUG("[VULKAN]: %s", strings.clone_from_cstring(callback_data.pMessage))
    }
    
    return false
}