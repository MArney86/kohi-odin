package vulkan_backend

import types "../../types"
import vk "../../../../libs/vulkan_lib"
import fmt "core:fmt"
import strings "core:strings"
import logger "../../core/logger"

vk_context : types.vulkan_context

initialize :: proc(backend: ^types.renderer_backend, application_name: string, plat_state: ^types.platform_state) -> b8 {
    loaded := vk.load()
    if !loaded {
        return false
    }
    
    //TODO: custome allocator
    vk_context.allocator = nil

    app_info: vk.ApplicationInfo = {vk.StructureType.APPLICATION_INFO,nil,nil,0,nil,0,0}
    app_info.apiVersion = vk.API_VERSION_1_4
    app_info.pApplicationName = strings.clone_to_cstring(application_name)
    app_info.applicationVersion = vk.MAKE_VERSION(1, 0, 0)
    app_info.pEngineName = "Kohi Engine"
    app_info.engineVersion = vk.MAKE_VERSION(1, 0, 0)

    create_info: vk.InstanceCreateInfo = {vk.StructureType.INSTANCE_CREATE_INFO,nil,vk.InstanceCreateFlags(nil),nil,0,nil,0,nil}
    create_info.pApplicationInfo = &app_info
    create_info.enabledExtensionCount = 0
    create_info.ppEnabledExtensionNames = nil
    create_info.enabledLayerCount = 0
    create_info.ppEnabledLayerNames = nil

    result: vk.Result = vk.CreateInstance(&create_info, vk_context.allocator, &vk_context.instance)
    if result != .SUCCESS {
        logger.ERROR("vkCreateInstance failed with result: %s", fmt.enum_value_to_string(result))
        return false
    }

    return true
}

shutdown :: proc(backend: ^types.renderer_backend) {
    // Vulkan-specific shutdown code here
    vk.unload()
}

on_resized :: proc(backend: ^types.renderer_backend, width: u16, height: u16) {
    // Vulkan-specific resize handling code here
}

begin_frame :: proc(backend: ^types.renderer_backend, delta_time: f32) -> b8 {
    // Vulkan-specific begin frame code here
    return true
}

end_frame :: proc(backend: ^types.renderer_backend, delta_time: f32) -> b8 {
    // Vulkan-specific end frame code here
    return true
}