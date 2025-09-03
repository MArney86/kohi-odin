package Kcore

import Types "../types"

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
app_state := application_state{}

application_create :: proc "odin" (game_inst: ^Types.game) -> b8 {
    if initialized {
        KERROR("application_create called more than once.")
        return false
    }

    app_state.game_inst = game_inst

    //initialize subsystems
    initialize_logging()

    //TODO: Remove this
    KFATAL("A test message: %f", 3.14)
    KERROR("A test message: %f", 3.14)
    KWARN("A test message: %f", 3.14)
    KINFO("A test message: %f", 3.14)
    KDEBUG("A test message: %f", 3.14)
    KTRACE("A test message: %f", 3.14)

    app_state.is_running = TRUE
    app_state.is_suspended = FALSE

    if !platform_startup(&app_state.platform, 
                          game_inst.app_config.name, 
                          cast(i32)game_inst.app_config.start_pos_x, 
                          cast(i32)game_inst.app_config.start_pos_y, 
                          cast(i32)game_inst.app_config.width, 
                          cast(i32)game_inst.app_config.height) {
        return FALSE
    }

    app_state.game_inst.on_resize(app_state.game_inst, cast(u32)app_state.width, cast(u32)app_state.height)

    initialized = TRUE

    return TRUE
}

application_run :: proc "odin" () -> b8 {
    for app_state.is_running {
        if !platform_pump_messages(&app_state.platform) {
            app_state.is_running = FALSE
        }

        if !app_state.is_suspended {
            if !app_state.game_inst.update(app_state.game_inst, cast(f32)0) {
                KFATAL("Game update failed, shutting down.")
                app_state.is_running = FALSE
                break
            }

            if !app_state.game_inst.render(app_state.game_inst, cast(f32)0) {
                KFATAL("Game render failed, shutting down.")
                app_state.is_running = FALSE
                break
            }
        }
    }

    app_state.is_running = FALSE

    platform_shutdown(&app_state.platform)

    return TRUE
}