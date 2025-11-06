package types

import vk "../../../libs/vulkan_lib"

vulkan_context :: struct {
    instance: vk.Instance,
    allocator: ^vk.AllocationCallbacks,
}