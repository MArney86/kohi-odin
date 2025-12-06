package vulkan_backend

import "core:strings"
import "base:runtime"
import logger "../../../core/logger"
import types "../../../types"
import str "../../../core/string"
import mem "../../../core/memory"
import darray "../../../containers/darray"
import vk "vendor:vulkan/dynamic"

vulkan_physical_device_requirements :: struct {
    graphics: b8,
    present: b8,
    compute: b8,
    transfer: b8,
    device_extension_names: ^[dynamic]cstring,
    sampler_anisotropy: b8,
    discrete_gpu: b8,
}

vulkan_physical_device_queue_family_info :: struct {
    graphics_family_index: i32,
    present_family_index: i32,
    compute_family_index: i32,
    transfer_family_index: i32,
}

select_physical_device :: proc(vk_context : ^types.vulkan_context) -> bool {
    physical_device_count: u32 = 0
    vk.CHECK(vk.EnumeratePhysicalDevices(vk_context.instance, &physical_device_count, nil))
    if physical_device_count == 0 {
        logger.FATAL("No devices which support Vulkan were found!")
        return false
    }

    physical_devices := make([]vk.PhysicalDevice, physical_device_count)
    defer delete(physical_devices)
    vk.CHECK(vk.EnumeratePhysicalDevices(vk_context.instance, &physical_device_count, raw_data(physical_devices)))
    for i:u32=0; i<physical_device_count; i+=1 {
        properties: vk.PhysicalDeviceProperties
        vk.GetPhysicalDeviceProperties(physical_devices[i], &properties)
        features: vk.PhysicalDeviceFeatures
        vk.GetPhysicalDeviceFeatures(physical_devices[i], &features)
        memory: vk.PhysicalDeviceMemoryProperties
        vk.GetPhysicalDeviceMemoryProperties(physical_devices[i], &memory)

        //TODO: These requirements should probably be driven by engine config
        requirements: vulkan_physical_device_requirements = {}
        requirements.graphics = true
        requirements.present = true
        requirements.transfer = true
        // enable for compute
        // requirements.compute = true
        requirements.sampler_anisotropy = true
        requirements.discrete_gpu = true
        extensions_temp: [dynamic]cstring = darray.i_make(cstring)
        requirements.device_extension_names = &extensions_temp
        darray.i_push(requirements.device_extension_names, strings.clone_to_cstring(vk.KHR_SWAPCHAIN_EXTENSION_NAME))

        queue_info: vulkan_physical_device_queue_family_info = {}
        result: bool = physical_device_meets_requirements(physical_devices[i], vk_context.surface, &properties, &features, &requirements, &queue_info, &vk_context.device.swapchain_support)

        if result {
            logger.INFO ("Selected device: '%s'.", strings.clone_from_bytes(properties.deviceName[:]))
            // GPU type, etc.
            switch (properties.deviceType) {
                case .OTHER:
                    logger.INFO("GPU type: Unknown")
                case .INTEGRATED_GPU:
                    logger.INFO("GPU type: Integrated")
                case .DISCRETE_GPU:
                    logger.INFO("GPU type: Discrete")
                case .VIRTUAL_GPU:
                    logger.INFO("GPU type: Virtual")
                case .CPU:
                    logger.INFO("GPU type: CPU")
            }

            logger.INFO("GPU Driver Version: %d.%d.%d", 
                vk.VERSION_MAJOR(properties.driverVersion), 
                vk.VERSION_MINOR(properties.driverVersion), 
                vk.VERSION_PATCH(properties.driverVersion))

            // Vulkan API version
            logger.INFO("Vulkan API Version: %d.%d.%d", 
                vk.VERSION_MAJOR(properties.apiVersion), 
                vk.VERSION_MINOR(properties.apiVersion), 
                vk.VERSION_PATCH(properties.apiVersion))
            
            // Memory information
            for j:u32=0; j<memory.memoryHeapCount; j+=1 {
                memory_size_gib: f32 = cast(f32)memory.memoryHeaps[j].size / 1024.0 / 1024.0 / 1024.0
                if memory.memoryHeaps[j].flags & {.DEVICE_LOCAL} != {} {
                    logger.INFO("Local GPU Memory: %.2f GiB", memory_size_gib)
                } else {
                    logger.INFO("Shared System Memory : %.2f GiB", memory_size_gib)
                }
            }

            vk_context.device.physical_device = physical_devices[i]
            vk_context.device.graphics_queue_index = cast(i32)queue_info.graphics_family_index
            vk_context.device.present_queue_index = cast(i32)queue_info.present_family_index
            vk_context.device.transfer_queue_index = cast(i32)queue_info.transfer_family_index
            // NOTE: set compute index here if needed
            // keep a copy of properties/features/memory
            vk_context.device.properties = properties
            vk_context.device.features = features
            vk_context.device.memory = memory
            break 
        }
        darray.i_delete(requirements.device_extension_names)
    }
    //ensure a device was selected
    if vk_context.device.physical_device == nil {
        logger.FATAL("Failed to find a suitable GPU!")
        return false
    }

    logger.INFO("Physical device selected.")
    return true
}

physical_device_meets_requirements :: proc(
    device: vk.PhysicalDevice, 
    surface: vk.SurfaceKHR, 
    properties: ^vk.PhysicalDeviceProperties, 
    features: ^vk.PhysicalDeviceFeatures,
    requirements: ^vulkan_physical_device_requirements,
    out_queue_info: ^vulkan_physical_device_queue_family_info,
    out_swapchain_support: ^types.vulkan_swapchain_support_info) -> bool {
    
    // Evaluate device properties to determine if it meets the requirements
    out_queue_info.graphics_family_index = -1
    out_queue_info.present_family_index = -1
    out_queue_info.compute_family_index = -1
    out_queue_info.transfer_family_index = -1

    // Discrete GPU check
    if requirements.discrete_gpu {
        if properties.deviceType != .DISCRETE_GPU {
            logger.INFO("Device is not a discrete GPU, and one is required. Skipping.")
            return false
        }
    }

    queue_family_count: u32 = 0
    vk.GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, nil)
    queue_families := make([]vk.QueueFamilyProperties, queue_family_count)
    defer delete(queue_families)
    vk.GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, raw_data(queue_families))

    // look at each queue and see what queues it supports
    logger.INFO("Graphics   | Present   | Compute   | Transfer  | Name")
    min_transfer_score: u8 = 255
    for i:u32=0; i<queue_family_count; i+=1 {
        current_transfer_score: u8 = 0
        //Graphics?
        if queue_families[i].queueFlags & {.GRAPHICS} != {} {
            out_queue_info.graphics_family_index = cast(i32)i
            current_transfer_score += 1
        }

        //Compute?
        if queue_families[i].queueFlags & {.COMPUTE} != {} {
            out_queue_info.compute_family_index = cast(i32)i
            current_transfer_score += 1
        }

        //Transfer?
        if queue_families[i].queueFlags & {.TRANSFER} != {} {
            //take the index if it is the current lowest. This increases the likelihood that it is a dedicated transfer queue
            if current_transfer_score < min_transfer_score {
                min_transfer_score = current_transfer_score
                out_queue_info.transfer_family_index = cast(i32)i
            }
        }

        //Present?
        present_support: b32 = false
        vk.CHECK(vk.GetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &present_support))
        if present_support != false {
            out_queue_info.present_family_index = cast(i32)i
        }
    }
    
    spacer :: proc(value: bool) -> string {
        ret: string = ""
        if value{
            return "       TRUE"
        } else {
            return "      FALSE"
        }
        
    }

    logger.INFO("%v|%v|%v|%v| %s", 
                spacer(out_queue_info.graphics_family_index != -1),
                spacer(out_queue_info.present_family_index != -1),
                spacer(out_queue_info.compute_family_index != -1),
                spacer(out_queue_info.transfer_family_index != -1),
                strings.clone_from_bytes(properties.deviceName[:]))
    
    if (!requirements.graphics || (requirements.graphics && out_queue_info.graphics_family_index != -1)) &&
       (!requirements.present || (requirements.present && out_queue_info.present_family_index != -1)) &&
       (!requirements.compute || (requirements.compute && out_queue_info.compute_family_index != -1)) &&
       (!requirements.transfer || (requirements.transfer && out_queue_info.transfer_family_index != -1)) {
        logger.INFO("Device meets queue requirements.")
        logger.TRACE("Graphics Family Index: %i", out_queue_info.graphics_family_index)
        logger.TRACE("Present Family Index: %i", out_queue_info.present_family_index)
        logger.TRACE("Compute Family Index: %i", out_queue_info.compute_family_index)
        logger.TRACE("Transfer Family Index: %i", out_queue_info.transfer_family_index)

        // Queue swapchain support.
        device_query_swapchain_support(device, surface, out_swapchain_support)
        if out_swapchain_support.format_count < 1 || out_swapchain_support.present_mode_count < 1 {
            if out_swapchain_support.formats != nil {
                mem.Free(out_swapchain_support.formats, cast(u64)size_of(vk.SurfaceFormatKHR) * cast(u64)out_swapchain_support.format_count, types.memory_tag.MEMORY_TAG_RENDERER)
                out_swapchain_support.formats = nil
            }
            if out_swapchain_support.present_modes != nil {
                mem.Free(out_swapchain_support.present_modes, cast(u64)size_of(vk.PresentModeKHR) * cast(u64)out_swapchain_support.present_mode_count, types.memory_tag.MEMORY_TAG_RENDERER)
                out_swapchain_support.present_modes = nil
            }
            logger.INFO("Required swapchain support not present, skipping device.")
            return false
        }
        

        // Device Extensions
        if requirements.device_extension_names != nil {
            available_extension_count: u32 = 0
            available_extensions: [dynamic]vk.ExtensionProperties = darray.i_make(vk.ExtensionProperties)
            vk.CHECK(vk.EnumerateDeviceExtensionProperties(device, nil, &available_extension_count, nil))
            if available_extension_count != 0 {
                expanded := darray.i_reserve(&available_extensions, cast(u64)available_extension_count)
                if !expanded {
                    logger.FATAL("Failed to allocate array for device extensions.")
                    darray.i_delete(&available_extensions)
                    return false
                }
                raw := cast(^runtime.Raw_Dynamic_Array)(&available_extensions)
                vk.CHECK(vk.EnumerateDeviceExtensionProperties(device, nil, &available_extension_count, cast([^]vk.ExtensionProperties)raw.data))
                raw.len = cast(int)available_extension_count

                required_extension_count: u32 = cast(u32)len(requirements.device_extension_names)
                for i:u32=0; i<required_extension_count; i+=1 {
                    found: bool = false
                    for j:u32=0; j<available_extension_count; j+=1 {
                        if str.equals(requirements.device_extension_names[i], str.bytes_to_cstr(available_extensions[j].extensionName[:])) {
                            found = true
                            break
                        }
                    }

                    if !found {
                        logger.INFO("Required extension not found: %s, skipping device.", cast(string)requirements.device_extension_names[i])
                        darray.i_delete(&available_extensions)
                        return false
                    }
                }
            }
            darray.i_delete(&available_extensions)
        }

        // Sampler Anisotropy
        if requirements.sampler_anisotropy && !features.samplerAnisotropy{
            logger.INFO("Device does not support sampler anisotropy, skipping.")
            return false
        }

        // Device meets all requirements
        return true
    }

    return false
}

device_create :: proc(vk_context : ^types.vulkan_context) -> bool {
    if !select_physical_device(vk_context) {
        return false
    }

    logger.INFO("Creating logical device...")
    // NOTE: DO NOT create additional queues for shared indices
    present_shares_graphics_queue: bool = vk_context.device.graphics_queue_index == vk_context.device.present_queue_index
    transfer_shares_graphics_queue: bool = vk_context.device.graphics_queue_index == vk_context.device.transfer_queue_index
    index_count: u32 = 1
    if !present_shares_graphics_queue {
        index_count += 1
    }
    if !transfer_shares_graphics_queue {
        index_count += 1
    }
    
    indices: [3]u32
    index: u8 = 0
    indices[index] = cast(u32)vk_context.device.graphics_queue_index
    index += 1
    if !present_shares_graphics_queue {
        indices[index] = cast(u32)vk_context.device.present_queue_index
        index += 1
    }
    if !transfer_shares_graphics_queue {
        indices[index] = cast(u32)vk_context.device.transfer_queue_index
        index += 1
    }

    queue_create_infos: [3]vk.DeviceQueueCreateInfo
    queue_priority: f32 = 1.0
    for i:u32=0; i<index_count; i+=1 {
        queue_create_infos[i].sType = vk.StructureType.DEVICE_QUEUE_CREATE_INFO
        queue_create_infos[i].queueFamilyIndex = indices[i]
        queue_create_infos[i].queueCount = 1
        //TODO: enable this for future enhancement
        //if indices[i] == cast(u32)vk_context.device.graphics_queue_index {
        //    queue_create_infos[i].queueCount = 2
        //}
        queue_create_infos[i].flags = nil
        queue_create_infos[i].pNext = nil
        queue_create_infos[i].pQueuePriorities = &queue_priority
    }

    //Request device features
    //TODO: should be driven by engine config
    device_features: vk.PhysicalDeviceFeatures = {}
    device_features.samplerAnisotropy = true //request anisotropic filtering support

    device_create_info: vk.DeviceCreateInfo = {}
    device_create_info.sType = vk.StructureType.DEVICE_CREATE_INFO
    device_create_info.queueCreateInfoCount = index_count
    device_create_info.pQueueCreateInfos = &queue_create_infos[0]
    device_create_info.pEnabledFeatures = &device_features
    device_create_info.enabledExtensionCount = 1
    extension_names: [1]cstring
    extension_names[0] = cstring(vk.KHR_SWAPCHAIN_EXTENSION_NAME)
    device_create_info.ppEnabledExtensionNames = &extension_names[0]

    //Deprecated and ignored, so pass nothing
    device_create_info.enabledLayerCount = 0
    device_create_info.ppEnabledLayerNames = nil

    vk.CHECK(vk.CreateDevice(vk_context.device.physical_device, &device_create_info, vk_context.allocator, &vk_context.device.logical_device))
    logger.INFO("Logical device created successfully.")

    vk.GetDeviceQueue(vk_context.device.logical_device, cast(u32)vk_context.device.graphics_queue_index, 0, &vk_context.device.graphics_queue)
    vk.GetDeviceQueue(vk_context.device.logical_device, cast(u32)vk_context.device.present_queue_index, 0, &vk_context.device.present_queue)
    vk.GetDeviceQueue(vk_context.device.logical_device, cast(u32)vk_context.device.transfer_queue_index, 0, &vk_context.device.transfer_queue)
    logger.INFO("Acquired device queues successfully.")

    return true
}

device_destroy :: proc(vk_context : ^types.vulkan_context) {
    
    // Null out queues
    vk_context.device.graphics_queue = nil
    vk_context.device.present_queue = nil
    vk_context.device.transfer_queue = nil

    // Destroy logical device
    logger.INFO("Destroying logical device...")
    if vk_context.device.logical_device != nil {
        vk.DestroyDevice(vk_context.device.logical_device, vk_context.allocator)
        vk_context.device.logical_device = nil
    }

    logger.INFO("Releasing physical device resources...")
    vk_context.device.physical_device = nil

    if vk_context.device.swapchain_support.formats != nil {
        darray.i_delete(vk_context.device.swapchain_support.formats)
        vk_context.device.swapchain_support.formats = nil
        vk_context.device.swapchain_support.format_count = 0
    }

    if vk_context.device.swapchain_support.present_modes != nil {
        darray.i_delete(vk_context.device.swapchain_support.present_modes)
        vk_context.device.swapchain_support.present_modes = nil
        vk_context.device.swapchain_support.present_mode_count = 0
    }

    mem.zero_memory(&vk_context.device.swapchain_support.capabilities, size_of(vk_context.device.swapchain_support.capabilities))
    
    vk_context.device.graphics_queue_index = -1
    vk_context.device.present_queue_index = -1
    vk_context.device.transfer_queue_index = -1
}

device_query_swapchain_support :: proc(
    physical_device: vk.PhysicalDevice, 
    surface: vk.SurfaceKHR, 
    out_support_info: ^types.vulkan_swapchain_support_info) {
    // Capabilities
    vk.CHECK(vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &out_support_info.capabilities))
    // Formats
    vk.CHECK(vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &out_support_info.format_count, nil))
    if out_support_info.format_count != 0 {
        if out_support_info.formats == nil {
            formats := darray.i_make(vk.SurfaceFormatKHR)
            out_support_info.formats = &formats
            out_test := darray.i_reserve(out_support_info.formats, cast(u64)out_support_info.format_count)
            if !out_test{
                logger.FATAL("Failed to allocate properly sized array for swapchain formats.")
                return
            }
            raw := cast(^runtime.Raw_Dynamic_Array)out_support_info.formats
            raw.len = cast(int)out_support_info.format_count
        }
        vk.CHECK(vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &out_support_info.format_count, raw_data(out_support_info.formats^)))
        
    }
    // Present Modes
    vk.CHECK(vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &out_support_info.present_mode_count, nil))
    if out_support_info.present_mode_count != 0 {
        if out_support_info.present_modes == nil {
            present_modes := darray.i_make(vk.PresentModeKHR)
            out_support_info.present_modes = &present_modes
            if !darray.i_reserve(out_support_info.present_modes, cast(u64)out_support_info.present_mode_count) {
                logger.FATAL("Failed to reserve capacity for swapchain present modes.")
                return
            }
            raw := cast(^runtime.Raw_Dynamic_Array)out_support_info.present_modes
            raw.len = cast(int)out_support_info.present_mode_count
        }
        vk.CHECK(vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &out_support_info.present_mode_count, raw_data(out_support_info.present_modes^)))
    }
}

device_detect_depth_format :: proc(device: ^types.vulkan_device) -> bool {
    candidate_count: u64 = 3
    candidates: [3]vk.Format = {
        vk.Format.D32_SFLOAT,
        vk.Format.D32_SFLOAT_S8_UINT,
        vk.Format.D24_UNORM_S8_UINT
    }

    flags := vk.FormatFeatureFlags{.DEPTH_STENCIL_ATTACHMENT}

    for i:u64=0; i<candidate_count; i+=1 {
        properties: vk.FormatProperties
        vk.GetPhysicalDeviceFormatProperties(device.physical_device, candidates[i], &properties)

        if (properties.linearTilingFeatures & flags) == flags {
            device.depth_format = candidates[i]
            return true
        } else if (properties.optimalTilingFeatures & flags) == flags {
            device.depth_format = candidates[i]
            return true
        }
    }

    return false
}