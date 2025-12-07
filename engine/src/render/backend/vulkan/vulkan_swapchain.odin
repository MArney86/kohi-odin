package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import logger "../../../core/logger"
import mem "../../../core/memory"
import fmt "core:fmt"

@(private="file")
_create :: proc(vk_context: ^types.vulkan_context, width: u32, height: u32, swapchain: ^types.vulkan_swapchain) {
    swapchain_extent: vk.Extent2D = {width, height}
    swapchain.max_frames_in_flight = 2

    found: bool = false
    for i:u32=0; i<vk_context.device.swapchain_support.format_count; i+=1 {
        format: vk.SurfaceFormatKHR = vk_context.device.swapchain_support.formats[i]
        if format.format == .B8G8R8A8_UNORM && format.colorSpace == .SRGB_NONLINEAR {
            swapchain.image_format = format
            found = true
            break
        }

        if !found {
            swapchain.image_format = vk_context.device.swapchain_support.formats[0]
        }

        present_mode: vk.PresentModeKHR = .FIFO
        for i:u32=0; i<vk_context.device.swapchain_support.present_mode_count; i+=1 {
            mode: vk.PresentModeKHR = vk_context.device.swapchain_support.present_modes[i]
            if mode == .MAILBOX {
                present_mode = .MAILBOX
                break
            }
        }

        //requery swapchain support info
        device_query_swapchain_support(vk_context.device.physical_device, vk_context.surface, &vk_context.device.swapchain_support)

        //Swapchain extent
        if vk_context.device.swapchain_support.capabilities.currentExtent.width != ~u32(0) {
            swapchain_extent = vk_context.device.swapchain_support.capabilities.currentExtent
        }

        //clamp to the value allowed by the GPU
        min: vk.Extent2D = vk_context.device.swapchain_support.capabilities.minImageExtent
        max: vk.Extent2D = vk_context.device.swapchain_support.capabilities.maxImageExtent
        swapchain_extent.width = clamp(swapchain_extent.width, min.width, max.width)
        swapchain_extent.height = clamp(swapchain_extent.height, min.height, max.height)

        //Image count
        image_count: u32 = vk_context.device.swapchain_support.capabilities.minImageCount + 1
        if vk_context.device.swapchain_support.capabilities.maxImageCount > 0 && 
           image_count > vk_context.device.swapchain_support.capabilities.maxImageCount 
           {
            image_count = vk_context.device.swapchain_support.capabilities.maxImageCount
        }

        //Create swapchain info
        swapchain_create_info: vk.SwapchainCreateInfoKHR
        swapchain_create_info.sType = vk.StructureType.SWAPCHAIN_CREATE_INFO_KHR
        swapchain_create_info.minImageCount = image_count
        swapchain_create_info.imageFormat = swapchain.image_format.format
        swapchain_create_info.imageColorSpace = swapchain.image_format.colorSpace
        swapchain_create_info.imageExtent = swapchain_extent
        swapchain_create_info.imageArrayLayers = 1
        swapchain_create_info.imageUsage = {.COLOR_ATTACHMENT}

        //Queue family indices
        if vk_context.device.graphics_queue_index != vk_context.device.present_queue_index {
            queue_family_indices: [2]u32 = {cast(u32)vk_context.device.graphics_queue_index, cast(u32)vk_context.device.present_queue_index}
            swapchain_create_info.imageSharingMode = .CONCURRENT
            swapchain_create_info.queueFamilyIndexCount = 2
            swapchain_create_info.pQueueFamilyIndices = &queue_family_indices[0]
        } else {
            swapchain_create_info.imageSharingMode = .EXCLUSIVE
            swapchain_create_info.queueFamilyIndexCount = 0
            swapchain_create_info.pQueueFamilyIndices = nil
        }

        swapchain_create_info.preTransform = vk_context.device.swapchain_support.capabilities.currentTransform
        swapchain_create_info.compositeAlpha = {.OPAQUE}
        swapchain_create_info.presentMode = present_mode
        swapchain_create_info.clipped = true
        swapchain_create_info.oldSwapchain = 0

        vk.CHECK(vk.CreateSwapchainKHR(vk_context.device.logical_device, &swapchain_create_info, vk_context.allocator, &swapchain.handle))

        swapchain.image_count = 0
        vk.CHECK(vk.GetSwapchainImagesKHR(vk_context.device.logical_device, swapchain.handle, &swapchain.image_count, nil))
        if swapchain.images == nil {
            swapchain.images = cast([^]vk.Image)mem.Allocate(cast(u64)size_of(vk.Image) * cast(u64)swapchain.image_count, .MEMORY_TAG_RENDERER)
        }
        if swapchain.views == nil {
            swapchain.views = cast([^]vk.ImageView)mem.Allocate(cast(u64)size_of(vk.ImageView) * cast(u64)swapchain.image_count, .MEMORY_TAG_RENDERER)
        }
        vk.CHECK(vk.GetSwapchainImagesKHR(vk_context.device.logical_device, swapchain.handle, &swapchain.image_count, &swapchain.images[0]))

        for i:u32=0; i<swapchain.image_count; i+=1 {
            view_info: vk.ImageViewCreateInfo
            view_info.sType = vk.StructureType.IMAGE_VIEW_CREATE_INFO
            view_info.image = swapchain.images[i]
            view_info.viewType = .D2
            view_info.format = swapchain.image_format.format
            view_info.subresourceRange.aspectMask = vk.ImageAspectFlags{.COLOR}
            view_info.subresourceRange.baseMipLevel = 0
            view_info.subresourceRange.levelCount = 1
            view_info.subresourceRange.baseArrayLayer = 0
            view_info.subresourceRange.layerCount = 1

            vk.CHECK(vk.CreateImageView(vk_context.device.logical_device, &view_info, vk_context.allocator, &swapchain.views[i]))
        }
        
        //depth resources
        if !device_detect_depth_format(&vk_context.device) {
            vk_context.device.depth_format = .UNDEFINED
            logger.FATAL("Failed to find a supported depth format for the Vulkan device.")
        }

        //Create depth image and its view
        image_create(
            vk_context,
            swapchain_extent.width,
            swapchain_extent.height,
            vk_context.device.depth_format,
            .OPTIMAL,
            {.DEPTH_STENCIL_ATTACHMENT},
            {.DEVICE_LOCAL},
            true,
            {.DEPTH},
            &swapchain.depth_attachment
        )
    }

    logger.INFO("Swapchain created successfully.")
}

@(private="file")
_destroy :: proc(vk_context: ^types.vulkan_context, swapchain: ^types.vulkan_swapchain) {
    image_destroy(vk_context, &swapchain.depth_attachment)
    
    //only destroy the views, not the images, since those are owned by the swapchain and are thus destroyed with it
    for i:u32=0; i<swapchain.image_count; i+=1 {
        vk.DestroyImageView(vk_context.device.logical_device, swapchain.views[i], vk_context.allocator)
    }

    vk.DestroySwapchainKHR(vk_context.device.logical_device, swapchain.handle, vk_context.allocator)
}

swapchain_create :: proc(vk_context: ^types.vulkan_context, width: u32, height: u32, out_swapchain: ^types.vulkan_swapchain) {
    _create(vk_context, width, height, out_swapchain)
}

swapchain_recreate :: proc(vk_context: ^types.vulkan_context, width: u32, height: u32, swapchain: ^types.vulkan_swapchain) {
    _destroy(vk_context, swapchain)
    _create(vk_context, width, height, swapchain)
}

swapchain_destroy :: proc(vk_context: ^types.vulkan_context, swapchain: ^types.vulkan_swapchain) {
    _destroy(vk_context, swapchain)
}

swapchain_aquire_next_image_index :: proc(vk_context: ^types.vulkan_context, 
                                          swapchain: ^types.vulkan_swapchain, 
                                          timeout_ns: u64, 
                                          image_available_semaphore: vk.Semaphore, 
                                          fence: vk.Fence, out_image_index: ^u32) -> bool {
    result: vk.Result = vk.AcquireNextImageKHR(vk_context.device.logical_device, 
                                               swapchain.handle, timeout_ns, 
                                               image_available_semaphore, fence, out_image_index)
    if result == .ERROR_OUT_OF_DATE_KHR {
        swapchain_recreate(vk_context, vk_context.framebuffer_width, vk_context.framebuffer_height, swapchain)
        return false
    } else if result != .SUCCESS && result != .SUBOPTIMAL_KHR {
        logger.ERROR("Failed to acquire swapchain image. vk.AcquireNextImageKHR returned: %s", result)
        return false
    }
    return true
}

swapchain_present :: proc(vk_context: ^types.vulkan_context, 
                          swapchain: ^types.vulkan_swapchain, 
                          graphics_queue: vk.Queue, 
                          present_queue: vk.Queue, 
                          render_complete_semaphore: vk.Semaphore, 
                          present_image_index: u32) {
    wait_semaphores := [1]vk.Semaphore{render_complete_semaphore}
    swapchains := [1]vk.SwapchainKHR{swapchain.handle}
    image_indices := [1]u32{present_image_index}
    
    present_info: vk.PresentInfoKHR
    present_info.sType = vk.StructureType.PRESENT_INFO_KHR
    present_info.pNext = nil
    present_info.waitSemaphoreCount = 1
    present_info.pWaitSemaphores = &wait_semaphores[0]
    present_info.swapchainCount = 1
    present_info.pSwapchains = &swapchains[0]
    present_info.pImageIndices = &image_indices[0]
    present_info.pResults = nil

    result: vk.Result = vk.QueuePresentKHR(present_queue, &present_info)
    if result == .ERROR_OUT_OF_DATE_KHR || result == .SUBOPTIMAL_KHR {
        swapchain_recreate(vk_context, vk_context.framebuffer_width, vk_context.framebuffer_height, swapchain)
    } else if result != .SUCCESS {
        logger.ERROR("Failed to present swapchain image. vk.QueuePresentKHR returned: %s", result)
    }
}
