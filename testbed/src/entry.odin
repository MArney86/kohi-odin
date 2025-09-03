package Testbed

import Types "../../engine/src/types"

// Boolean constants
TRUE :: true
FALSE :: false

// Platform-specific import for the engine library
when ODIN_OS == .Windows {
    foreign import Engine "../../bin/engine.lib"
} else when ODIN_OS == .Linux {
    foreign import Engine "../../bin/libengine.so"
} else {
    #panic("Unsupported platform")
}

foreign Engine {
    /* Application Layer */
    application_create :: proc "c" (game_inst: rawptr) -> b8 ---
    application_run :: proc "c" () -> b8 ---
    
    /* Platform Layer */
    platform_allocate :: proc "c" (size: u64, aligned: b8) -> rawptr ---
    platform_free :: proc "c" (block: rawptr, aligned: b8) ---
    
    /* Logger functions */
    KFATAL :: proc "c" (msg: cstring) ---
    KINFO :: proc "c" (msg: cstring) ---
    KDEBUG :: proc "c" (msg: cstring) ---
}

main :: proc() {

    //create the game instance
    game_inst: Types.game

    //populate the game instance
    if !create_game(&game_inst) {
        KFATAL(cstring("Could not create game!"))
        return
    }

    //ensure all required function pointers are set
    if game_inst.initialize == nil || 
       game_inst.update == nil || 
       game_inst.render == nil || 
       game_inst.on_resize == nil {
        KFATAL(cstring("Game is missing required function pointers!"))
        return
    }

    //create the application
    if !application_create(&game_inst) {
        KINFO(cstring("Application failed to create!"))
        return
    }

    //run the application
    if !application_run() {
        KINFO(cstring("Application did not shutdown gracefully"))
        return
    }
}