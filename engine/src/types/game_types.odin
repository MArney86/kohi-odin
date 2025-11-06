package types

application_config :: struct {
    start_pos_x: i16,
    start_pos_y: i16,
    width: i16,
    height: i16,
    name: string,
}

game_initialize_func :: proc(^game) -> b8
game_update_func :: proc(^game, f32) -> b8
game_render_func :: proc(^game, f32) -> b8
game_resize_func :: proc(^game, u32, u32)

game :: struct {
    app_config: application_config,
    initialize: game_initialize_func,
    update:     game_update_func,
    render:     game_render_func,
    on_resize:  game_resize_func,
    state:      rawptr,
} 