package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import logger "../../../core/logger"

fence_create :: proc(
    vk_context : ^types.vulkan_context,
    create_signaled : bool,
    out_fence : ^types.vulkan_fence) {

    // Make sure to signal the fence if required.
    out_fence.is_signaled = create_signaled
    fence_create_info : vk.FenceCreateInfo 
    fence_create_info.sType = .FENCE_CREATE_INFO
    if out_fence.is_signaled {
        fence_create_info.flags = {.SIGNALED}
    }

    vk.CHECK(vk.CreateFence(
        vk_context.device.logical_device,
        &fence_create_info,
        vk_context.allocator,
        &out_fence.handle));
}

fence_destroy :: proc(
    vk_context : ^types.vulkan_context,
    fence : ^types.vulkan_fence) {

    if fence.handle != 0 {
        vk.DestroyFence(
            vk_context.device.logical_device,
            fence.handle,
            vk_context.allocator)
        fence.handle = 0
    }
    fence.is_signaled = false
}

fence_wait :: proc(
    vk_context : ^types.vulkan_context,
    fence : ^types.vulkan_fence,
    timeout_ns : u64) -> bool {

    if !fence.is_signaled {
        result : vk.Result = vk.WaitForFences(
            vk_context.device.logical_device,
            1,
            &fence.handle,
            true,
            timeout_ns);
        #partial switch result {
            case .SUCCESS:
                fence.is_signaled = true;
                return true;

            case .TIMEOUT:
                logger.WARN("vk_fence_wait - Timed out")

            case .ERROR_DEVICE_LOST:
                logger.ERROR("vk_fence_wait - VK_ERROR_DEVICE_LOST.")
                
            case .ERROR_OUT_OF_HOST_MEMORY:
                logger.ERROR("vk_fence_wait - VK_ERROR_OUT_OF_HOST_MEMORY.")
            
            case .ERROR_OUT_OF_DEVICE_MEMORY:
                logger.ERROR("vk_fence_wait - VK_ERROR_OUT_OF_DEVICE_MEMORY.")
        
            case:
                logger.ERROR("vk_fence_wait - An unknown error has occurred.");
        }
    } else {
        // If already signaled, do not wait.
        return true
    }

    return false
}

fence_reset :: proc(
    vk_context: ^types.vulkan_context, 
    fence: ^types.vulkan_fence) {
    if fence.is_signaled {
        vk.CHECK(vk.ResetFences(vk_context.device.logical_device, 1, &fence.handle));
        fence.is_signaled = false
    }
}