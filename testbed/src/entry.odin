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
    application_create :: proc "c" (game_inst: ^Types.game) -> b8 ---
    application_run :: proc "c" () -> b8 ---
    KFATAL :: proc "c" (msg: cstring) ---
    KINFO :: proc "c" (msg: cstring) ---
}

main :: proc() {

    game_inst: Types.game

    if !create_game(&game_inst) {
        KFATAL(cstring("Could not create game!"))
        return
    }

    if game_inst.initialize == nil || 
       game_inst.update == nil || 
       game_inst.render == nil || 
       game_inst.on_resize == nil {
        KFATAL(cstring("Game is missing required function pointers!"))
        return
    }

    if !application_create(&game_inst) {
        KINFO(cstring("Application failed to create!"))
        return
    }

    if !application_run() {
        KINFO(cstring("Application did not shutdown gracefully"))
        return
    }
}