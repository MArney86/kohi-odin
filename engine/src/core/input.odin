package core

import types "../types"

@(private="file")
keyboard_state :: struct {
    keys: [256]b8,
}

@(private="file")
mouse_state :: struct {
    x: i16,
    y: i16,
    buttons: [int(types.buttons.BUTTON_MAX_BUTTONS)]u8,
}

@(private)
input_state :: struct {
    keyboard_current: keyboard_state,
    keyboard_previous: keyboard_state,
    mouse_current: mouse_state,
    mouse_previous: mouse_state,
}

//Internal input state
@(private="file")
input_initialized: b8 = FALSE
@(private="file")
state_input: input_state

// Input system
@(private)
input_initialize :: proc() {
    Kzero_memory(&state_input, size_of(state_input))
    input_initialized = TRUE
    KINFO("Input subsystem initalized")
}

@(private)
input_shutdown :: proc() {
    //TODO: add shutdown routines when needed
    input_initialized = FALSE
}

@(private)
input_update :: proc(delta_time: f32) {
    if !input_initialized {
        return
    }

    // copy current states to previous states
    Kcopy_memory(&state_input.keyboard_previous, &state_input.keyboard_current, size_of(keyboard_state))
    Kcopy_memory(&state_input.mouse_previous, &state_input.mouse_current, size_of(mouse_state))
}

//keyboard input
@(export)
K_is_key_down :: proc(key: types.keys) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.keyboard_current.keys[int(key)]) == TRUE
}

@(export)
K_is_key_up :: proc(key: types.keys) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.keyboard_current.keys[int(key)]) == FALSE
}

@(export)
K_was_key_down :: proc(key: types.keys) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.keyboard_previous.keys[int(key)]) == TRUE
}

@(export)
K_was_key_up :: proc(key: types.keys) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.keyboard_previous.keys[int(key)]) == FALSE
}

@(private)
input_process_key :: proc(key: types.keys, pressed: b8) {
    //only handle if the state actually changed
    if b8(state_input.keyboard_current.keys[int(key)]) != pressed {
        //KDEBUG("Key %d %s", key, pressed ? "pressed" : "released")
        //update internal state
        state_input.keyboard_current.keys[int(key)] = pressed

        // fire off event for immediate processing
        context_event: types.event_context
        context_event.data.U16[0] = cast(u16)key
        Kevent_fire(cast(u16)(pressed ? types.system_event_codes.EVENT_CODE_KEY_PRESSED : types.system_event_codes.EVENT_CODE_KEY_RELEASED), nil, context_event)


    }

}

//mouse input
@(export)
K_is_button_down :: proc(button: types.buttons) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.mouse_current.buttons[int(button)]) == TRUE
}

@(export)
K_is_button_up :: proc(button: types.buttons) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.mouse_current.buttons[int(button)]) == FALSE
}

@(export)
K_was_button_down :: proc(button: types.buttons) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.mouse_previous.buttons[int(button)]) == TRUE
}

@(export)
K_was_button_up :: proc(button: types.buttons) -> b8 {
    if !input_initialized {
        return FALSE
    }
    return bool(state_input.mouse_previous.buttons[int(button)]) == FALSE
}

@(export)
K_get_mouse_position :: proc(x: ^i32, y: ^i32) {
    if !input_initialized {
        x^ = 0
        y^ = 0
        return
    }
    x^ = cast(i32)state_input.mouse_current.x
    y^ = cast(i32)state_input.mouse_current.y
}

@(export)
K_get_previous_mouse_position :: proc(x: ^i32, y: ^i32) {
    if !input_initialized {
        x^ = 0
        y^ = 0
        return
    }
    x^ = cast(i32)state_input.mouse_previous.x
    y^ = cast(i32)state_input.mouse_previous.y
}

input_process_button :: proc(button: types.buttons, pressed: b8) {
    //if state changed, fire an event
    if b8(state_input.mouse_current.buttons[int(button)]) != pressed {
        //update internal state
        state_input.mouse_current.buttons[int(button)] = cast(u8)pressed

        // fire off event for immediate processing
        context_event: types.event_context
        context_event.data.U16[0] = cast(u16)button
        Kevent_fire(u16(pressed ? types.system_event_codes.EVENT_CODE_BUTTON_PRESSED : types.system_event_codes.EVENT_CODE_BUTTON_RELEASED), nil, context_event)
    }
}

input_process_mouse_move :: proc(x: i16, y: i16) {
    //only process if actually different
    if state_input.mouse_current.x != x || state_input.mouse_current.y != y {
        //NOTE: Enable this if debugging
        //KDEBUG("Mouse moved to position: (%d, %d)", x, y)

        //update internal state
        state_input.mouse_current.x = x
        state_input.mouse_current.y = y

        // fire off event for immediate processing
        context_event: types.event_context
        context_event.data.U16[0] = cast(u16)x
        context_event.data.U16[1] = cast(u16)y
        Kevent_fire(u16(types.system_event_codes.EVENT_CODE_MOUSE_MOVED), nil, context_event)
    }
}

input_process_mouse_wheel :: proc(z_delta: i8) {
    //NOTE: no internal state to update

    // fire off event for immediate processing
    context_event: types.event_context
    context_event.data.U8[0] = cast(u8)z_delta
    Kevent_fire(u16(types.system_event_codes.EVENT_CODE_MOUSE_WHEEL), nil, context_event)
}