package types
application_config :: struct {
    start_pos_x: i16,
    start_pos_y: i16,
    width: i16,
    height: i16,
    name: string,
}

initialize_func :: proc(^game) -> b8
update_func :: proc(^game, f32) -> b8
render_func :: proc(^game, f32) -> b8
resize_func :: proc(^game, u32, u32)

game :: struct {
    app_config: application_config,
    initialize: initialize_func,
    update:     update_func,
    render:     render_func,
    on_resize:  resize_func,
    state:      rawptr,
} 