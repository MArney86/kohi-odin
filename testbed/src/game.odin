package Testbed

import "core:fmt"

import Types "../../engine/src/types"

game_state :: struct {
    delta_time: f32,
}

//game creation function definition
create_game :: proc(out_game: ^Types.game) -> b8 {
    //populate the game instance
    out_game.app_config = Types.application_config{
        start_pos_x = 100,
        start_pos_y = 100,
        width = 1280,
        height = 720,
        name = "kohi Engine Testbed",
    }
    //ensure all required function pointers are set
    out_game.initialize = game_initialize
    out_game.update    = game_update
    out_game.render    = game_render
    out_game.on_resize = game_on_resize

    //allocate memory for game state
    out_game.state = platform_allocate(size_of(game_state), FALSE)

    return TRUE
}

// game initialization function
game_initialize :: proc(game_inst: ^Types.game) -> b8 {
    KDEBUG("Game Initialized")
   return TRUE
}

// game update function
game_update :: proc(game_inst: ^Types.game, delta_time: f32) -> b8 {
   return TRUE
}

// game render function
game_render :: proc(game_inst: ^Types.game, delta_time: f32) -> b8 {
   return TRUE
}

// game resize function
game_on_resize :: proc(game_inst: ^Types.game, width: u32, height: u32) {
    return
}