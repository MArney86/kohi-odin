package Testbed

import "core:mem"
import types "../../engine/src/types"

// Boolean constants
TRUE :: true
FALSE :: false

main :: proc() {
    //initialize memory management
    initialize_memory()

    //create the game instance
    game_inst: types.game

    //populate the game instance
    if !create_game(&game_inst) {
        KFATAL("Could not create game!")
        return
    }

    //ensure all required function pointers are set
    if game_inst.initialize == nil || 
       game_inst.update == nil || 
       game_inst.render == nil || 
       game_inst.on_resize == nil {
        KFATAL("Game is missing required function pointers!")
        return
    }

    //create the application
    if !application_create(&game_inst) {
        KINFO("Application failed to create!")
        return
    }

    //run the application
    if !application_run() {
        KINFO("Application did not shutdown gracefully")
        return
    }

    //shutdown memory management
    shutdown_memory()
}