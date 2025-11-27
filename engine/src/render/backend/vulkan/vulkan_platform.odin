package vulkan_backend

import types "../../../types"
import vk "vendor:vulkan/dynamic"
import plat "../../../core/platform"

get_required_extension_names :: proc(names_darray: ^[dynamic]cstring) {
    plat.get_required_extension_names(names_darray)
}

create_vulkan_surface :: proc(plat_state: ^types.platform_state, vulkan_context: ^types.vulkan_context) -> bool {
    return plat.create_vulkan_surface(plat_state, vulkan_context)
}