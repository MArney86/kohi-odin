package core

import Types "../types"
import strings "core:strings"

@(private)
application_state :: struct {
    game_inst: ^Types.game,
    is_running: b8,
    is_suspended: b8,
    platform: platform_state, 
    width: i16,
    height: i16,
    last_time: f64
}

@(private)
initialized: b8 = FALSE
@(private)
state_app := application_state{}

@(export)
application_create :: proc "odin" (game_inst: ^Types.game) -> b8 {
    if initialized {
        KERROR("application_create called more than once.")
        return false
    }

    state_app.game_inst = game_inst

    //initialize subsystems
    initialize_logging()
    input_initialize()

    //TODO: Remove this
    KFATAL("A test message: %f", 3.14)
    KERROR("A test message: %f", 3.14)
    KWARN("A test message: %f", 3.14)
    KINFO("A test message: %f", 3.14)
    KDEBUG("A test message: %f", 3.14)
    KTRACE("A test message: %f", 3.14)

    state_app.is_running = TRUE
    state_app.is_suspended = FALSE

    if !event_initialize() {
        KERROR("Event system failed initialization. Application cannot continue.")
        return FALSE
    }

    if !platform_startup(&state_app.platform, 
                         game_inst.app_config.name, 
                         cast(i32)game_inst.app_config.start_pos_x, 
                         cast(i32)game_inst.app_config.start_pos_y, 
                         cast(i32)game_inst.app_config.width, 
                         cast(i32)game_inst.app_config.height) {
        return FALSE
    }

    state_app.game_inst.on_resize(state_app.game_inst, cast(u32)state_app.width, cast(u32)state_app.height)

    initialized = TRUE

    return TRUE
}

@(export)
application_run :: proc "odin" () -> b8 {
    KINFO(get_memory_usage_str())

    for state_app.is_running {
        if !platform_pump_messages(&state_app.platform) {
            state_app.is_running = FALSE
        }

        if !state_app.is_suspended {
            if !state_app.game_inst.update(state_app.game_inst, cast(f32)0) {
                KFATAL("Game update failed, shutting down.")
                state_app.is_running = FALSE
                break
            }

            if !state_app.game_inst.render(state_app.game_inst, cast(f32)0) {
                KFATAL("Game render failed, shutting down.")
                state_app.is_running = FALSE
                break
            }

            //NOTE: input update/state copying should always be handled 
            // after any input should be recorded; I.E. before this line.
            // As a safety, input is the last thing to be updated before
            // this frame ends
            input_update(cast(f32)0)
        }
    }

    state_app.is_running = FALSE

    event_shutdown()
    input_shutdown()

    platform_shutdown(&state_app.platform)

    return TRUE
}