package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import mem "../../../core/memory"

renderpass_create :: proc(vk_context: ^types.vulkan_context, 
                     out_renderpass: ^types.vulkan_renderpass,
                     x: f32, y: f32, w: f32, h: f32,
                     r: f32, g: f32, b: f32, a: f32,
                     depth: f32, stencil: u32) {
    
    //Main subpass
    subpass : vk.SubpassDescription
    subpass.pipelineBindPoint = .GRAPHICS

    //Attachment TODO: make configurable
    attachment_description_count: u32 = 2
    attachment_descriptions: [2]vk.AttachmentDescription

    //Color attachment
    color_attachment: vk.AttachmentDescription
    color_attachment.format = vk_context.swapchain.image_format.format // TODO: make configurable
    color_attachment.samples = {._1}
    color_attachment.loadOp = .CLEAR
    color_attachment.storeOp = .STORE
    color_attachment.stencilLoadOp = .DONT_CARE
    color_attachment.stencilStoreOp = .DONT_CARE
    color_attachment.initialLayout = .UNDEFINED //don't expect layout
    color_attachment.finalLayout = .PRESENT_SRC_KHR // transition to after render pass
    color_attachment.flags = vk.AttachmentDescriptionFlags(nil)
    attachment_descriptions[0] = color_attachment

    color_attachment_reference: vk.AttachmentReference
    color_attachment_reference.attachment = 0 // attachment description array index
    color_attachment_reference.layout = .COLOR_ATTACHMENT_OPTIMAL
    
    subpass.colorAttachmentCount = 1
    subpass.pColorAttachments = &color_attachment_reference

    //Depth attachment if there is one
    depth_attachment: vk.AttachmentDescription
    depth_attachment.format = vk_context.device.depth_format // TODO: make configurable
    depth_attachment.samples = {._1}
    depth_attachment.loadOp = .CLEAR
    depth_attachment.storeOp = .DONT_CARE
    depth_attachment.stencilLoadOp = .DONT_CARE
    depth_attachment.stencilStoreOp = .DONT_CARE
    depth_attachment.initialLayout = .UNDEFINED
    depth_attachment.finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    
    attachment_descriptions[1] = depth_attachment

    depth_attachment_reference: vk.AttachmentReference
    depth_attachment_reference.attachment = 1 // attachment description array index
    depth_attachment_reference.layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL

    //TODO: other attachment types (input, resolve, preserve)

    //depth stencil data
    subpass.pDepthStencilAttachment = &depth_attachment_reference

    //input from shader
    subpass.inputAttachmentCount = 0
    subpass.pInputAttachments = nil

    //attachments used for multisampling color attachments
    subpass.pResolveAttachments = nil

    //attachemnts not used in the subpass, but whose data must be preserved
    subpass.preserveAttachmentCount = 0
    subpass.pPreserveAttachments = nil

    //render pass dependencies
    dependency: vk.SubpassDependency
    dependency.srcSubpass = vk.SUBPASS_EXTERNAL
    dependency.dstSubpass = 0
    dependency.srcStageMask = {.COLOR_ATTACHMENT_OUTPUT}
    dependency.srcAccessMask = {}
    dependency.dstStageMask = {.COLOR_ATTACHMENT_OUTPUT}
    dependency.dstAccessMask = {.COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE}
    dependency.dependencyFlags = {}

    //Render pass create
    render_pass_create_info: vk.RenderPassCreateInfo
    render_pass_create_info.sType = vk.StructureType.RENDER_PASS_CREATE_INFO
    render_pass_create_info.attachmentCount = attachment_description_count
    render_pass_create_info.pAttachments = &attachment_descriptions[0]
    render_pass_create_info.subpassCount = 1
    render_pass_create_info.pSubpasses = &subpass
    render_pass_create_info.dependencyCount = 1
    render_pass_create_info.pDependencies = &dependency
    render_pass_create_info.pNext = nil
    render_pass_create_info.flags = vk.RenderPassCreateFlags(nil)

    vk.CHECK(vk.CreateRenderPass(vk_context.device.logical_device, &render_pass_create_info, vk_context.allocator, &out_renderpass.handle))
}

renderpass_destroy :: proc(vk_context: ^types.vulkan_context, renderpass: ^types.vulkan_renderpass) {
    if (renderpass.handle != 0) && (renderpass != nil) {
        vk.DestroyRenderPass(vk_context.device.logical_device, renderpass.handle, vk_context.allocator)
        renderpass.handle = 0
    }
}

renderpass_begin :: proc(command_buffer: ^types.vulkan_command_buffer, renderpass: ^types.vulkan_renderpass, framebuffer: vk.Framebuffer) {
    begin_info: vk.RenderPassBeginInfo
    begin_info.sType = vk.StructureType.RENDER_PASS_BEGIN_INFO
    begin_info.renderPass = renderpass.handle
    begin_info.framebuffer = framebuffer
    begin_info.renderArea.offset.x = cast(i32)renderpass.x
    begin_info.renderArea.offset.y = cast(i32)renderpass.y
    begin_info.renderArea.extent.width = cast(u32)renderpass.w
    begin_info.renderArea.extent.height = cast(u32)renderpass.h

    clear_values: [2]vk.ClearValue
    mem.zero_memory(&clear_values[0], size_of(vk.ClearValue) * 2)
    clear_values[0].color.float32[0] = renderpass.r
    clear_values[0].color.float32[1] = renderpass.g
    clear_values[0].color.float32[2] = renderpass.b
    clear_values[0].color.float32[3] = renderpass.a
    clear_values[1].depthStencil.depth = renderpass.depth
    clear_values[1].depthStencil.stencil = renderpass.stencil

    begin_info.clearValueCount = 2
    begin_info.pClearValues = &clear_values[0]

    vk.CmdBeginRenderPass(command_buffer.handle, &begin_info, vk.SubpassContents.INLINE)
    command_buffer.state = .IN_RENDER_PASS
}

renderpass_end :: proc(command_buffer: ^types.vulkan_command_buffer, renderpass: ^types.vulkan_renderpass) {
    vk.CmdEndRenderPass(command_buffer.handle)
    command_buffer.state = .RECORDING
}