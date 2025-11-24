package testbed

import KAPI "../../libs/KAPI"

game_state :: struct {
    delta_time: f32,
}

//game creation function definition
create_game :: proc(out_game: ^KAPI.game) -> bool {
    //populate the game instance
    KAPI.DEBUG("Populating game instance...")
    out_game.app_config = KAPI.application_config{
        start_pos_x = 100,
        start_pos_y = 100,
        width = 1280,
        height = 720,
        name = "kohi Engine Testbed",
    }
    //ensure all required function pointers are set
    KAPI.DEBUG("Setting game function pointers...")
    out_game.initialize = game_initialize
    out_game.update    = game_update
    out_game.render    = game_render
    out_game.on_resize = game_on_resize

    //allocate memory for game state
    KAPI.DEBUG("Allocating memory for game state...")
    out_game.state = KAPI.allocate(size_of(game_state), .MEMORY_TAG_GAME)

    return TRUE
}

// game initialization function
game_initialize :: proc(game_inst: ^KAPI.game) -> bool {
    KAPI.DEBUG("Game Initialized")
    return TRUE
}

// game update function
game_update :: proc(game_inst: ^KAPI.game, delta_time: f32) -> bool {
    return TRUE
}

// game render function
game_render :: proc(game_inst: ^KAPI.game, delta_time: f32) -> bool {
    return TRUE
}

// game resize function
game_on_resize :: proc(game_inst: ^KAPI.game, width: u32, height: u32) {
    return
}