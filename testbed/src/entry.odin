package testbed

import types "../../engine/src/types"

import os "core:os"
import mem "core:mem"
import fmt "core:fmt"
import strings "core:strings"
import strconv "core:strconv"
import KAPI "../../libs/KAPI"

// Boolean constants
TRUE :: true
FALSE :: false

main :: proc() {
    fmt.println("Testbed starting...")
    
    //Load shared libraries
    fmt.println("Loading kohi API...")
    kohi_ok := KAPI.initialize_kohi_api()
    if !kohi_ok {
        fmt.eprintf("Could not load kohi engine API!\n")
        return
    }
    fmt.println("Kohi API loaded successfully")

    //initialize memory management
    fmt.println("Initializing memory...")
    KAPI.initialize_memory()

    //create the game instance
    game_inst: KAPI.game

    //populate the game instance
    if !create_game(&game_inst) {
        KAPI.FATAL("Could not create game!")
        return
    }

    //ensure all required function pointers are set
    if game_inst.initialize == nil || 
       game_inst.update == nil || 
       game_inst.render == nil || 
       game_inst.on_resize == nil {
        KAPI.FATAL("Game is missing required function pointers!")
        return
    }

    //create the application
    if !KAPI.application_create(&game_inst) {
        KAPI.INFO("Application failed to create!")
        return
    }

    //run the application
    if !KAPI.application_run() {
        KAPI.INFO("Application did not shutdown gracefully")
        return
    }

    //shutdown memory management
    KAPI.shutdown_memory()
    KAPI.shutdown_kohi_api()
}