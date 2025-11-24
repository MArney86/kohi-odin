package input

import types "../../types"
import event "../event"
import memory "../memory"
import logger "../logger"

keyboard_state :: struct {
    keys: [256]b8,
}

mouse_state :: struct {
    x: i16,
    y: i16,
    buttons: [int(types.buttons.BUTTON_MAX_BUTTONS)]u8,
}

input_state :: struct {
    keyboard_current: keyboard_state,
    keyboard_previous: keyboard_state,
    mouse_current: mouse_state,
    mouse_previous: mouse_state,
}

//Internal input state
@(private="file")
initialized: bool = false
@(private="file")
state: input_state

// Input system
initialize :: proc() {
    memory.zero_memory(&state, size_of(state))
    initialized = true
    logger.INFO("Input subsystem initalized")
}

shutdown :: proc() {
    //TODO: add shutdown routines when needed
    initialized = false
}

update :: proc(delta_time: f64) {
    if !initialized {
        return
    }

    // copy current states to previous states
    memory.copy_memory(&state.keyboard_previous, &state.keyboard_current, size_of(keyboard_state))
    memory.copy_memory(&state.mouse_previous, &state.mouse_current, size_of(mouse_state))
}

//keyboard input
@(export)
is_key_down :: proc(key: types.keys) -> bool {
    if !initialized {
        return false
    }
    return bool(state.keyboard_current.keys[int(key)]) == true
}

@(export)
is_key_up :: proc(key: types.keys) -> bool {
    if !initialized {
        return false
    }
    return bool(state.keyboard_current.keys[int(key)]) == false
}

@(export)
was_key_down :: proc(key: types.keys) -> bool {
    if !initialized {
        return false
    }
    return bool(state.keyboard_previous.keys[int(key)]) == true
}

@(export)
was_key_up :: proc(key: types.keys) -> bool {
    if !initialized {
        return false
    }
    return bool(state.keyboard_previous.keys[int(key)]) == false
}

process_key :: proc(key: types.keys, pressed: bool) {
    //only handle if the state actually changed
    if bool(state.keyboard_current.keys[int(key)]) != pressed {
        //KDEBUG("Key %d %s", key, pressed ? "pressed" : "released")
        //update internal state
        state.keyboard_current.keys[int(key)] = cast(b8)pressed

        // fire off event for immediate processing
        event_context: types.event_context
        event_context.data.U16[0] = cast(u16)key
        event.fire(cast(u16)(pressed ? types.system_event_codes.EVENT_CODE_KEY_PRESSED : types.system_event_codes.EVENT_CODE_KEY_RELEASED), nil, event_context)


    }

}

//mouse input
@(export)
is_button_down :: proc(button: types.buttons) -> bool {
    if !initialized {
        return false
    }
    return bool(state.mouse_current.buttons[int(button)]) == true
}

@(export)
is_button_up :: proc(button: types.buttons) -> bool {
    if !initialized {
        return false
    }
    return bool(state.mouse_current.buttons[int(button)]) == false
}

@(export)
was_button_down :: proc(button: types.buttons) -> bool {
    if !initialized {
        return false
    }
    return bool(state.mouse_previous.buttons[int(button)]) == true
}

@(export)
was_button_up :: proc(button: types.buttons) -> bool {
    if !initialized {
        return false
    }
    return bool(state.mouse_previous.buttons[int(button)]) == false
}

@(export)
get_mouse_position :: proc(x: ^i32, y: ^i32) {
    if !initialized {
        x^ = 0
        y^ = 0
        return
    }
    x^ = cast(i32)state.mouse_current.x
    y^ = cast(i32)state.mouse_current.y
}

@(export)
get_previous_mouse_position :: proc(x: ^i32, y: ^i32) {
    if !initialized {
        x^ = 0
        y^ = 0
        return
    }
    x^ = cast(i32)state.mouse_previous.x
    y^ = cast(i32)state.mouse_previous.y
}

process_button :: proc(button: types.buttons, pressed: bool) {
    //if state changed, fire an event
    if bool(state.mouse_current.buttons[int(button)]) != pressed {
        //update internal state
        state.mouse_current.buttons[int(button)] = cast(u8)pressed

        // fire off event for immediate processing
        event_context: types.event_context
        event_context.data.U16[0] = cast(u16)button
        event.fire(u16(pressed ? types.system_event_codes.EVENT_CODE_BUTTON_PRESSED : types.system_event_codes.EVENT_CODE_BUTTON_RELEASED), nil, event_context)
    }
}

process_mouse_move :: proc(x: i16, y: i16) {
    //only process if actually different
    if state.mouse_current.x != x || state.mouse_current.y != y {
        //NOTE: Enable this if debugging
        //KDEBUG("Mouse moved to position: (%d, %d)", x, y)

        //update internal state
        state.mouse_current.x = x
        state.mouse_current.y = y

        // fire off event for immediate processing
        event_context: types.event_context
        event_context.data.U16[0] = cast(u16)x
        event_context.data.U16[1] = cast(u16)y
        event.fire(u16(types.system_event_codes.EVENT_CODE_MOUSE_MOVED), nil, event_context)
    }
}

process_mouse_wheel :: proc(z_delta: i8) {
    //NOTE: no internal state to update

    // fire off event for immediate processing
    event_context: types.event_context
    event_context.data.U8[0] = cast(u8)z_delta
    event.fire(u16(types.system_event_codes.EVENT_CODE_MOUSE_WHEEL), nil, event_context)
}