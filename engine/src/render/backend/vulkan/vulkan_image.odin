package vulkan_backend
import types "../../../types"
import vk "vendor:vulkan/dynamic"
import logger "../../../core/logger"
import mem "../../../core/memory"

image_create :: proc(vk_context: ^types.vulkan_context, 
                     width: u32, height: u32, 
                     format: vk.Format, tiling: vk.ImageTiling, 
                     usage: vk.ImageUsageFlags, 
                     memory_flags: vk.MemoryPropertyFlags, 
                     create_view: bool, 
                     view_aspect_flags: vk.ImageAspectFlags, 
                     out_image: ^types.vulkan_image) {
    //copy parameters
    out_image.width = width
    out_image.height = height

    //Creation info
    create_info: vk.ImageCreateInfo
    create_info.sType = .IMAGE_CREATE_INFO
    create_info.imageType = .D2
    create_info.extent.width = width
    create_info.extent.height = height
    create_info.extent.depth = 1 //TODO: Support configurable depth
    create_info.mipLevels = 4 // TODO: Support mipmapping
    create_info.arrayLayers = 1 //TODO: Support number of layers in image
    create_info.format = format
    create_info.tiling = tiling
    create_info.initialLayout = .UNDEFINED
    create_info.usage = usage
    create_info.sharingMode = .EXCLUSIVE //TODO: Configurable sharing mode
    create_info.samples = {._1} //TODO: Configurable sample count

    vk.CHECK(vk.CreateImage(vk_context.device.logical_device, &create_info, vk_context.allocator, &out_image.handle))

    //query memory requirements
    memory_requirements: vk.MemoryRequirements
    vk.GetImageMemoryRequirements(vk_context.device.logical_device, out_image.handle, &memory_requirements)

    memory_type: i32 = vk_context.find_memory_index(memory_requirements.memoryTypeBits, transmute(u32)memory_flags)
    if memory_type == -1 {
        logger.ERROR("Required memory type not found. Image not valid.")
    }

    //allocate memory
    memory_allocate_info: vk.MemoryAllocateInfo
    memory_allocate_info.sType = .MEMORY_ALLOCATE_INFO
    memory_allocate_info.allocationSize = memory_requirements.size
    memory_allocate_info.memoryTypeIndex = cast(u32)memory_type

    vk.CHECK(vk.AllocateMemory(vk_context.device.logical_device, &memory_allocate_info, vk_context.allocator, &out_image.memory))

    //bind memory
    vk.CHECK(vk.BindImageMemory(vk_context.device.logical_device, out_image.handle, out_image.memory, 0)) //TODO: Configurable memory offset

    //create view
    if create_view {
        out_image.view = 0;
        image_view_create(vk_context, format, out_image, view_aspect_flags)
    }
}

image_view_create :: proc(vk_context: ^types.vulkan_context, format: vk.Format, image: ^types.vulkan_image, aspect_flags: vk.ImageAspectFlags) {
    view_create_info: vk.ImageViewCreateInfo
    view_create_info.sType = .IMAGE_VIEW_CREATE_INFO
    view_create_info.image = image.handle
    view_create_info.viewType = .D2 //TODO: Configurable view type
    view_create_info.format = format
    view_create_info.subresourceRange.aspectMask = aspect_flags

    //TODO: make configurable
    view_create_info.subresourceRange.baseMipLevel = 0
    view_create_info.subresourceRange.levelCount = 1
    view_create_info.subresourceRange.baseArrayLayer = 0
    view_create_info.subresourceRange.layerCount = 1

    vk.CHECK(vk.CreateImageView(vk_context.device.logical_device, &view_create_info, vk_context.allocator, &image.view))
}

image_destroy :: proc(vk_context: ^types.vulkan_context, image: ^types.vulkan_image) {
    if image.view != 0 {
        vk.DestroyImageView(vk_context.device.logical_device, image.view, vk_context.allocator)
        image.view = 0
    }
    if image.memory != 0 {
        vk.FreeMemory(vk_context.device.logical_device, image.memory, vk_context.allocator)
        image.memory = 0
    }
    if image.handle != 0 {
        vk.DestroyImage(vk_context.device.logical_device, image.handle, vk_context.allocator)
        image.handle = 0
    }
}