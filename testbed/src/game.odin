package Testbed

import "core:fmt"

import Types "../../engine/src/types"

// Platform-specific import for the engine library
when ODIN_OS == .Windows {
    foreign import Engine "../../bin/engine.lib"
} else when ODIN_OS == .Linux {
    foreign import Engine "../../bin/libengine.so"
} else {
    #panic("Unsupported platform")
}

foreign Engine {
    platform_allocate :: proc "c" (size: u64, aligned: b8) -> rawptr ---
    platform_free :: proc "c" (block: rawptr, aligned: b8) ---
    KDEBUG :: proc "c" (msg: cstring) ---
}

game_state :: struct {
    delta_time: f32,
}

//game creation function definition
create_game :: proc(out_game: ^Types.game) -> b8 {
    out_game.app_config = Types.application_config{
        start_pos_x = 100,
        start_pos_y = 100,
        width = 1280,
        height = 720,
        name = "kohi Engine Testbed",
    }
    out_game.initialize = game_initialize
    out_game.update    = game_update
    out_game.render    = game_render
    out_game.on_resize = game_on_resize
    out_game.state = platform_allocate(size_of(game_state), FALSE)

    return TRUE
}


game_initialize :: proc(game_inst: ^Types.game) -> b8 {
    KDEBUG("Game Initialized")
   return TRUE
}


game_update :: proc(game_inst: ^Types.game, delta_time: f32) -> b8 {
   return TRUE
}

game_render :: proc(game_inst: ^Types.game, delta_time: f32) -> b8 {
   return TRUE
}

game_on_resize :: proc(game_inst: ^Types.game, width: u32, height: u32) {
    return
}