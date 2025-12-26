package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import strings "core:strings"
import runtime "base:runtime"
import logger "../../../core/logger"
import darray "../../../containers/darray"
import memory "../../../core/memory"

vk_context: types.vulkan_context
cached_framebuffer_width: u32 = 0
cached_framebuffer_height: u32 = 0

initialize :: proc(
    backend: ^types.renderer_backend, 
    application_name: string, 
    plat_state: ^types.platform_state) -> bool {

    loaded := vk.initialize()
    if !loaded {
        logger.ERROR("Failed to load Vulkan library.")
        return false
    }
    // function pointers
    vk_context.find_memory_index = find_memory_index;

    //TODO: custom allocator
    vk_context.allocator = nil

    vk_context.framebuffer_width = cached_framebuffer_width !=0 ? cached_framebuffer_width : 800
    vk_context.framebuffer_height = cached_framebuffer_height !=0 ? cached_framebuffer_height : 600
    cached_framebuffer_width = 0
    cached_framebuffer_height = 0

    app_info: vk.ApplicationInfo = {vk.StructureType.APPLICATION_INFO,nil,nil,0,nil,0,0}
    app_info.apiVersion = vk.API_VERSION_1_4
    app_info.pApplicationName = strings.clone_to_cstring(application_name)
    app_info.applicationVersion = vk.MAKE_VERSION(1, 0, 0)
    app_info.pEngineName = "Kohi Engine"
    app_info.engineVersion = vk.MAKE_VERSION(1, 0, 0)

    create_info: vk.InstanceCreateInfo = {vk.StructureType.INSTANCE_CREATE_INFO,nil,vk.InstanceCreateFlags(nil),nil,0,nil,0,nil}
    create_info.pApplicationInfo = &app_info
    required_extensions := cast(^[dynamic]cstring)darray.make(typeid_of(cstring))
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
        required_validation_layers = cast(^[dynamic]cstring)darray.make(cstring)
        defer darray.delete(cast(rawptr)required_validation_layers, cstring)
        temp = "VK_LAYER_KHRONOS_validation"
        logger.INFO("Validation layers enabled. Enumerating...")
        darray.push(cast(rawptr)required_validation_layers, cstring, &temp)
        required_validation_count = cast(u32)len(required_validation_layers)

        available_layer_count: u32
        vk.CHECK(vk.EnumerateInstanceLayerProperties(&available_layer_count, nil))
        available_layers := cast(^[dynamic]vk.LayerProperties)darray.make(vk.LayerProperties)
        defer darray.delete(cast(rawptr)available_layers, vk.LayerProperties)
        darray.reserve(cast(rawptr)available_layers, vk.LayerProperties, cast(u64)available_layer_count)
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

    if !device_create(&vk_context) {
        logger.ERROR("Failed to create Vulkan device.")
        return false
    }

    //swapchain
    swapchain_create(&vk_context, vk_context.framebuffer_width, vk_context.framebuffer_height, &vk_context.swapchain)

    //main renderpass
    renderpass_create(&vk_context, &vk_context.main_renderpass, 0,0, cast(f32)vk_context.framebuffer_width, cast(f32)vk_context.framebuffer_height, 0, 0, 0.2, 1.0, 1.0, 0)

    //swapchain framebuffers
    vk_context.swapchain.framebuffers = cast(^[dynamic]types.vulkan_framebuffer)darray.make(typeid_of(types.vulkan_framebuffer))
    ok := darray.reserve(vk_context.swapchain.framebuffers, typeid_of(types.vulkan_framebuffer), cast(u64)vk_context.swapchain.image_count)
    if !ok {
        logger.FATAL("Failed to reserve memory for swapchain framebuffers.")
        return false
    }
    darray.set_len(vk_context.swapchain.framebuffers, typeid_of(types.vulkan_framebuffer), cast(u64)vk_context.swapchain.image_count)
    regenerate_framebuffers(backend, &vk_context.swapchain, &vk_context.main_renderpass)
    
    //command buffers
    create_command_buffers(backend)

    //create synchronization objects
    vk_context.image_available_semaphores = cast(^[dynamic]vk.Semaphore)darray.make(typeid_of(vk.Semaphore))
    ok = darray.reserve(vk_context.image_available_semaphores, cast(u64)vk_context.swapchain.max_frames_in_flight)
    if !ok {
        logger.FATAL("Failed to reserve memory for image available semaphores.")
        return false
    }
    vk_context.queue_complete_semaphores = cast(^[dynamic]vk.Semaphore)darray.make(typeid_of(vk.Semaphore))
    ok = darray.reserve(vk_context.queue_complete_semaphores, cast(u64)vk_context.swapchain.max_frames_in_flight)
    if !ok {
        logger.FATAL("Failed to reserve memory for queue complete semaphores.")
        return false
    }
    vk_context.in_flight_fences = cast(^[dynamic]types.vulkan_fence)darray.make(typeid_of(types.vulkan_fence))
    ok = darray.reserve(vk_context.in_flight_fences, cast(u64)vk_context.swapchain.max_frames_in_flight)
    if !ok {
        logger.FATAL("Failed to reserve memory for in-flight fences.")
        return false
    }

    for i:u8=0;i<vk_context.swapchain.max_frames_in_flight;i+=1 {
        semaphore_create_info: vk.SemaphoreCreateInfo = vk.SemaphoreCreateInfo{
            sType = vk.StructureType.SEMAPHORE_CREATE_INFO,
            pNext = nil,
            flags = vk.SemaphoreCreateFlags(nil),
        }
        darray.set_len(vk_context.image_available_semaphores, u64(i+1))
        vk.CreateSemaphore(vk_context.device.logical_device, &semaphore_create_info, vk_context.allocator, &vk_context.image_available_semaphores[i]);
        darray.set_len(vk_context.queue_complete_semaphores, u64(i+1))
        vk.CreateSemaphore(vk_context.device.logical_device, &semaphore_create_info, vk_context.allocator, &vk_context.queue_complete_semaphores[i]);
        
        // Create the fence in a signaled state, indicating that the first frame has already been "rendered".
        // This will prevent the application from waiting indefinitely for the first frame to render since it
        // cannot be rendered until a frame is "rendered" before it.
        darray.set_len(vk_context.in_flight_fences, u64(i+1))
        fence_create(&vk_context, true, &vk_context.in_flight_fences[i])
    }

    // In flight fences should not yet exist at this point, so clear the list. These are stored in pointers
    // because the initial state should be 0, and will be 0 when not in use. Acutal fences are not owned
    // by this list.
    vk_context.images_in_flight = cast(^[dynamic]^types.vulkan_fence)darray.make(typeid_of(^types.vulkan_fence))
    ok = darray.reserve(vk_context.images_in_flight, cast(u64)vk_context.swapchain.image_count)
    if !ok {
        logger.FATAL("Failed to reserve memory for images in flight fences.")
        return false
    }
    for i:u32=0;i<vk_context.swapchain.image_count;i+=1 {
        darray.set_len(vk_context.images_in_flight, u64(i+1))
        vk_context.images_in_flight[i] = nil
    }

    logger.INFO("Vulkan renderer initialized successfully.")
    return true
}

shutdown :: proc(backend: ^types.renderer_backend) {
    // Clean up Vulkan resources in reverse order of creation
    vk.DeviceWaitIdle(vk_context.device.logical_device)

    // Sync objects
    for i:u8=0;i<vk_context.swapchain.max_frames_in_flight;i+=1 {
        if vk_context.image_available_semaphores[i] != 0 {
            vk.DestroySemaphore(
                vk_context.device.logical_device,
                vk_context.image_available_semaphores[i],
                vk_context.allocator);
            vk_context.image_available_semaphores[i] = 0;
        }
        if vk_context.queue_complete_semaphores[i] != 0 {
            vk.DestroySemaphore(
                vk_context.device.logical_device,
                vk_context.queue_complete_semaphores[i],
                vk_context.allocator);
            vk_context.queue_complete_semaphores[i] = 0;
        }
        fence_destroy(&vk_context, &vk_context.in_flight_fences[i]);
    }
    darray.delete(vk_context.image_available_semaphores);
    vk_context.image_available_semaphores = nil;

    darray.delete(vk_context.queue_complete_semaphores);
    vk_context.queue_complete_semaphores = nil;

    darray.delete(vk_context.in_flight_fences);
    vk_context.in_flight_fences = nil;

    darray.delete(vk_context.images_in_flight);
    vk_context.images_in_flight = nil;

    //command buffers
    for i: u32; i < vk_context.swapchain.image_count; i += 1 {
        if vk_context.graphics_command_buffers[i].handle != nil {
            command_buffer_free(&vk_context, vk_context.device.graphics_command_pool, &vk_context.graphics_command_buffers[i])
        }
    }
    darray.delete(vk_context.graphics_command_buffers)
    vk_context.graphics_command_buffers = nil

    //framebuffers
    for i:u32=0;i<vk_context.swapchain.image_count; i+=1 {
        framebuffer_destroy(&vk_context, &vk_context.swapchain.framebuffers[i]);
    }

    renderpass_destroy(&vk_context, &vk_context.main_renderpass)

    swapchain_destroy(&vk_context, &vk_context.swapchain)

    logger.DEBUG("Destroying Vulkan device...")
    device_destroy(&vk_context)
        
    logger.DEBUG("Destroying Vulkan surface...")
    if vk_context.surface != vk.SurfaceKHR(0) {
        vk.DestroySurfaceKHR(vk_context.instance, vk_context.surface, vk_context.allocator)
        vk_context.surface = vk.SurfaceKHR(0)
    }
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

find_memory_index :: proc(type_filter: u32, property_flags: u32) -> i32 {
    memory_properties: vk.PhysicalDeviceMemoryProperties = vk.PhysicalDeviceMemoryProperties{}
    vk.GetPhysicalDeviceMemoryProperties(vk_context.device.physical_device, &memory_properties)

    flags := transmute(vk.MemoryPropertyFlags)property_flags
    for i:u32=0; i<memory_properties.memoryTypeCount; i += 1 {
        if (type_filter & (1 << i)) != 0 && (memory_properties.memoryTypes[i].propertyFlags & flags) == flags {
            return cast(i32)i
        }
    }

    logger.WARN("Unable to find suitable memory type!")
    return -1
}

@(private)
create_command_buffers :: proc(backend: ^types.renderer_backend) {
    if vk_context.graphics_command_buffers == nil {
        vk_context.graphics_command_buffers = cast(^[dynamic]types.vulkan_command_buffer)darray.make(typeid_of(types.vulkan_command_buffer))
        darray.reserve(cast(rawptr)vk_context.graphics_command_buffers, typeid_of(types.vulkan_command_buffer), cast(u64)vk_context.swapchain.image_count)
        darray.set_len(cast(rawptr)vk_context.graphics_command_buffers, typeid_of(types.vulkan_command_buffer), cast(u64)vk_context.swapchain.image_count)
        for i: u32; i < vk_context.swapchain.image_count; i += 1 {
            memory.zero_memory(&vk_context.graphics_command_buffers[i], size_of(types.vulkan_command_buffer))
        }
    }

    for i: u32; i < vk_context.swapchain.image_count; i += 1 {
        if vk_context.graphics_command_buffers[i].handle == nil {
            command_buffer_allocate(&vk_context, vk_context.device.graphics_command_pool, true, &vk_context.graphics_command_buffers[i])
        }
    }

    logger.DEBUG("Vulkan command buffers created.")
}

@(private)
regenerate_framebuffers :: proc(
    backend: ^types.renderer_backend,
    swapchain: ^types.vulkan_swapchain,
    renderpass: ^types.vulkan_renderpass) {

    for i:u32=0;i<swapchain.image_count;i+=1 {
    // TODO: make this dynamic based on the currently configured attachments
        attachment_count: u32 = 2
        attachments := [2]vk.ImageView {
            swapchain.views[i],
            swapchain.depth_attachment.view
        }

        framebuffer_create(
            &vk_context,
            renderpass,
            vk_context.framebuffer_width,
            vk_context.framebuffer_height,
            attachment_count,
            raw_data(&attachments),
            &vk_context.swapchain.framebuffers[i]);
    }
}

set_framebuffer_size :: proc(width: u32, height: u32) {
    cached_framebuffer_width = width
    cached_framebuffer_height = height
}