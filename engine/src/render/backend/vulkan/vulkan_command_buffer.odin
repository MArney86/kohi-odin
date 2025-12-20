package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import mem "../../../core/memory"

command_buffer_allocate :: proc(vk_context: ^types.vulkan_context, pool: vk.CommandPool, 
                                is_primary: bool, out_command_buffer: ^types.vulkan_command_buffer) {
    
    mem.zero_memory(out_command_buffer, size_of(types.vulkan_command_buffer))

    allocate_info: vk.CommandBufferAllocateInfo
    allocate_info.sType = vk.StructureType.COMMAND_BUFFER_ALLOCATE_INFO
    allocate_info.commandPool = pool
    allocate_info.level = is_primary ? .PRIMARY : .SECONDARY
    allocate_info.commandBufferCount = 1
    allocate_info.pNext = nil

    out_command_buffer.state = .NOT_ALLOCATED
    vk.CHECK(vk.AllocateCommandBuffers(vk_context.device.logical_device, &allocate_info, &out_command_buffer.handle))
    out_command_buffer.state = .READY
}

command_buffer_free :: proc(vk_context: ^types.vulkan_context, pool: vk.CommandPool, 
                             command_buffer: ^types.vulkan_command_buffer) {

    vk.FreeCommandBuffers(vk_context.device.logical_device, pool, 1, &command_buffer.handle)
    command_buffer.handle = nil
    command_buffer.state = .NOT_ALLOCATED
}

command_buffer_begin :: proc(command_buffer: ^types.vulkan_command_buffer, is_single_use: bool,
                             is_renderpass_continue: bool, is_simultaneous_use: bool) {

    begin_info: vk.CommandBufferBeginInfo
    begin_info.sType = vk.StructureType.COMMAND_BUFFER_BEGIN_INFO
    begin_info.flags = {}
    if is_single_use {
        begin_info.flags += {.ONE_TIME_SUBMIT}
    }
    if is_renderpass_continue {
        begin_info.flags += {.RENDER_PASS_CONTINUE}
    }
    if is_simultaneous_use {
        begin_info.flags += {.SIMULTANEOUS_USE}
    }

    vk.CHECK(vk.BeginCommandBuffer(command_buffer.handle, &begin_info))
    command_buffer.state = .RECORDING
}

command_buffer_end :: proc(command_buffer: ^types.vulkan_command_buffer) {
    vk.CHECK(vk.EndCommandBuffer(command_buffer.handle))
    command_buffer.state = .RECORDING_ENDED
}

command_buffer_update_submitted :: proc(command_buffer: ^types.vulkan_command_buffer) {
    command_buffer.state = .SUBMITTED
}

command_buffer_reset :: proc(command_buffer: ^types.vulkan_command_buffer) {
    command_buffer.state = .READY
}

command_buffer_allocate_and_begin_single_use :: proc(vk_context: ^types.vulkan_context, pool: vk.CommandPool,
                                                     out_command_buffer: ^types.vulkan_command_buffer) {
    command_buffer_allocate(vk_context, pool, true, out_command_buffer)
    command_buffer_begin(out_command_buffer, true, false, false)
}

command_buffer_end_single_use :: proc(vk_context: ^types.vulkan_context, pool: vk.CommandPool,
                                        command_buffer: ^types.vulkan_command_buffer, queue: vk.Queue) {
    command_buffer_end(command_buffer)
    submit_info: vk.SubmitInfo
    submit_info.sType = vk.StructureType.SUBMIT_INFO
    submit_info.commandBufferCount = 1
    submit_info.pCommandBuffers = &command_buffer.handle
    vk.CHECK(vk.QueueSubmit(queue, 1, &submit_info, vk.Fence(0)))

    vk.CHECK(vk.QueueWaitIdle(queue))

    command_buffer_free(vk_context, pool, command_buffer)
}