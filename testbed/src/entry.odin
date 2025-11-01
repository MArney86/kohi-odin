package testbed

import types "../../engine/src/types"

import os "core:os"
import mem "core:mem"
import fmt "core:fmt"
import strings "core:strings"
import strconv "core:strconv"

// Boolean constants
TRUE :: true
FALSE :: false

@(private)
version_file := "APIversion.txt"

main :: proc() {
    
    //Load shared libraries
    kohi_ok := load_kohi_api()
    if !kohi_ok {
        fmt.eprintf("Could not load kohi engine API!\n")
        return
    }

    //initialize memory management
    KAPI.initialize_memory()

    //create the game instance
    game_inst: types.game

    //populate the game instance
    if !create_game(&game_inst) {
        KAPI.KFATAL("Could not create game!")
        return
    }

    //ensure all required function pointers are set
    if game_inst.initialize == nil || 
       game_inst.update == nil || 
       game_inst.render == nil || 
       game_inst.on_resize == nil {
        KAPI.KFATAL("Game is missing required function pointers!")
        return
    }

    //create the application
    if !KAPI.application_create(&game_inst) {
        KAPI.KINFO("Application failed to create!")
        return
    }

    //run the application
    if !KAPI.application_run() {
        KAPI.KINFO("Application did not shutdown gracefully")
        return
    }

    //shutdown memory management
    KAPI.shutdown_memory()
    unload_kohi_api()
}