package vulkan_backend

import fmt "core:fmt"
import runtime "base:runtime"
import asserts "../../core/asserts"
import vk "../../../../libs/vulkan_lib"
import plat "../../core/platform"

get_required_extension_names :: proc(names_darray: ^[dynamic]cstring) {
    plat.get_required_extension_names(names_darray)
}

check :: proc (result: vk.Result, call: string = #caller_expression, loc: runtime.Source_Code_Location = #caller_location) {
        asserts.ASSERT_MSG(result == .SUCCESS, call, fmt.tprintf("Vulkan call '%s' failed with error code %s", call, fmt.enum_value_to_string(result)), loc)
}