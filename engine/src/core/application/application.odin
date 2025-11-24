package application

import types "../../types"
import strings "core:strings"
import logger "../logger"
import clock "../clock"
import input "../input"
import renderer "../../render/"
import memory "../memory"
import event "../event"
import platform "../platform"

application_state :: struct {
    game_inst: ^types.game,
    is_running: bool,
    is_suspended: bool,
    platform: types.platform_state, 
    width: i16,
    height: i16,
    clock: types.clock,
    last_time: f64
}

initialized: b8 = false
state : application_state

@(export)
create :: proc "odin" (game_inst: ^types.game) -> bool {
    if initialized {
        logger.ERROR("application_create called more than once.")
        return false
    }

    state.game_inst = game_inst

    //initialize subsystems
    logger.initialize()
    input.initialize()

    //TODO: Remove this
    logger.FATAL("A test message: %f", 3.14)
    logger.ERROR("A test message: %f", 3.14)
    logger.WARN("A test message: %f", 3.14)
    logger.INFO("A test message: %f", 3.14)
    logger.DEBUG("A test message: %f", 3.14)
    logger.TRACE("A test message: %f", 3.14)

    state.is_running = true
    state.is_suspended = false

    if !event.initialize() {
        logger.ERROR("Event system failed initialization. Application cannot continue.")
        return false
    }

    if !platform.startup(&state.platform, 
                         game_inst.app_config.name,
                         cast(i32)game_inst.app_config.start_pos_x, 
                         cast(i32)game_inst.app_config.start_pos_y, 
                         cast(i32)game_inst.app_config.width, 
                         cast(i32)game_inst.app_config.height) {
        return false
    }

    //renderer initialization
    if !renderer.initialize(game_inst.app_config.name,&state.platform) {
        logger.FATAL("Renderer failed to initialize! Aborting Application.")
        return false
    }
    
    //initialize the game
    if !state.game_inst.initialize(state.game_inst) {
        logger.FATAL("Game failed to initialize! Aborting Application.")
        return false
    }

    state.game_inst.on_resize(state.game_inst, cast(u32)state.width, cast(u32)state.height)

    initialized = true

    return true
}

@(export)
run :: proc "odin" () -> bool {
    clock.start(&state.clock)
    clock.update(&state.clock)
    state.last_time = state.clock.elapsed_time
    running_time: f64 = 0.0
    frame_count: u8 = 0
    target_frame_seconds: f64 = 1.0 / 60.0

    for state.is_running {
        if !platform.pump_messages(&state.platform) {
            state.is_running = false
        }

        if !state.is_suspended {
            //update clock and get delta time
            clock.update(&state.clock)
            current_time: f64 = state.clock.elapsed_time
            delta_time: f64 = current_time - state.last_time
            frame_start_time: f64 = platform.get_absolute_time()

            //update game
            if !state.game_inst.update(state.game_inst, cast(f32)delta_time) {
                logger.FATAL("Game update failed, shutting down.")
                state.is_running = false
                break
            }

            //render game
            if !state.game_inst.render(state.game_inst, cast(f32)delta_time) {
                logger.FATAL("Game render failed, shutting down.")
                state.is_running = false
                break
            }

            //TODO: refactor packet creation
            packet: types.render_packet
            packet.delta_time = cast(f32)delta_time
            renderer.draw_frame(&packet)

            // figure out how long the frame took and if below
            frame_end_time: f64 = platform.get_absolute_time()
            frame_elapsed_time: f64 = frame_end_time - frame_start_time
            running_time += frame_elapsed_time
            remaining_seconds: f64 = target_frame_seconds - frame_elapsed_time

            if remaining_seconds > 0.0 {
                remaining_ms: u64 = cast(u64)(remaining_seconds * 1000.0)

                //if there is time remaining, give it back to the OS
                limit_frames: bool = false
                if remaining_ms > 0 && limit_frames {
                    platform.sleep(remaining_ms - 1)
                }

                frame_count += 1
            }

            //NOTE: input update/state copying should always be handled 
            // after any input should be recorded; I.E. before this line.
            // As a safety, input is the last thing to be updated before
            // this frame ends
            input.update(delta_time)

            //update last time
            state.last_time = current_time
            when ODIN_DEBUG {
                if memory.stats.updated {
                    logger.DEBUG(memory.get_memory_usage_str())
                }
            }
        }
    }

    state.is_running = false
    event.shutdown()
    input.shutdown()

    platform.shutdown(&state.platform)
    return true
}