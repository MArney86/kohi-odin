package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import mem "../../../core/memory"

framebuffer_create :: proc(
    vk_context: ^types.vulkan_context,
    renderpass: ^types.vulkan_renderpass,
    width: u32,
    height: u32,
    attachment_count: u32,
    attachments: [^]vk.ImageView,
    out_framebuffer: ^types.vulkan_framebuffer) {

    // Take a copy of the attachments, renderpass and attachment count
    out_framebuffer.attachments = cast([^]vk.ImageView)mem.Allocate(u64(size_of(vk.ImageView) * attachment_count), .MEMORY_TAG_RENDERER)
    for i:u32=0;i<attachment_count;i+=1{
        out_framebuffer.attachments[i] = attachments[i]
    }
    out_framebuffer.renderpass = renderpass
    out_framebuffer.attachment_count = attachment_count

    // Creation info
    framebuffer_create_info : vk.FramebufferCreateInfo
    framebuffer_create_info.sType= .FRAMEBUFFER_CREATE_INFO
    framebuffer_create_info.renderPass = renderpass.handle
    framebuffer_create_info.attachmentCount = attachment_count;
    framebuffer_create_info.pAttachments = out_framebuffer.attachments;
    framebuffer_create_info.width = width;
    framebuffer_create_info.height = height;
    framebuffer_create_info.layers = 1;

    vk.CHECK(vk.CreateFramebuffer(
        vk_context.device.logical_device,
        &framebuffer_create_info,
        vk_context.allocator,
        &out_framebuffer.handle));
}

framebuffer_destroy :: proc(
    vk_context: ^types.vulkan_context, 
    framebuffer: ^types.vulkan_framebuffer) {

    vk.DestroyFramebuffer(vk_context.device.logical_device, framebuffer.handle, vk_context.allocator);
    if framebuffer.attachments != nil {
        mem.Free(framebuffer.attachments, u64(size_of(vk.ImageView) * framebuffer.attachment_count), .MEMORY_TAG_RENDERER);
        framebuffer.attachments = nil
    }
    framebuffer.handle = 0
    framebuffer.attachment_count = 0
    framebuffer.renderpass = nil
}