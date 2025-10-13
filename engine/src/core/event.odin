package core

import types "../types"

@(private)
PFN_on_event :: ^proc(code: u16, sender: rawptr, listener_inst: rawptr, data: types.event_context) -> b8
@(private)
MAX_MESSAGE_CODES :: 16384
@(private)
is_initialized: b8 = FALSE

@(private)
registered_event :: struct {
    listener: rawptr,
    callback: PFN_on_event,
}

@(private)
event_code_entry :: struct {
    events: ^[dynamic]registered_event,
}

@(private)
event_system_state :: struct {
    registered: [MAX_MESSAGE_CODES]event_code_entry,
}

state: event_system_state

@(private)
event_initialize :: proc() -> b8 {
    if is_initialized == TRUE {
        return FALSE
    }
    is_initialized = FALSE
    Kzero_memory(&state, size_of(state))
    is_initialized = TRUE;
    
    return TRUE
}

@(private)
event_shutdown :: proc() {
    for i: u16; i < MAX_MESSAGE_CODES; i += 1 {
        if &state.registered[i].events != nil {
            Kdelete(state.registered[i].events);
            state.registered[i].events = nil;
        }
    }
}

/*
 * Register to listen for when events are sent with the provided code. Events with duplicate
 * listener/callback combos will not be registered again and will cause this to return FALSE.
 * @param code the event code to listen for.
 * @param listener a pointer to the listener instance. Can be 0/nil.
 * @param on_event the callback function pointer to be invoked when the event code is fired.
 * @return TRUE if the event listener is successfully registered, FALSE otherwise.
 */
@(private)
Kevent_register :: proc(code: u16, listener_inst: rawptr, on_event: PFN_on_event) -> b8 {
    if is_initialized == FALSE {
        return FALSE
    }

    if state.registered[code].events == nil {
        array := Kdarray_make(registered_event)
        state.registered[code].events = cast(^[dynamic]registered_event)&array
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        if state.registered[code].events[i].listener == listener_inst {
            //TODO: Warn
            return FALSE
        }
    }

    event: registered_event
    event.listener = listener_inst
    event.callback = on_event
    if !Kdarray_push(state.registered[code].events, event) {
        KERROR("Failed to register event listener for code %d", code)
        return FALSE
    }
    return TRUE
}

/*
 * Unregister a previously registered event listener/callback combo.
 * @param code the event code to stop listening for.
 * @param listener a pointer to the listener instance. Can be 0/nil.
 * @param on_event the callback function pointer to be unregistered.
 * @return TRUE if the event listener is successfully unregistered, FALSE otherwise.
 */
@(private)
Kevent_unregister :: proc(code: u16, listener_inst: rawptr, on_event: PFN_on_event) -> b8 {
     if is_initialized == FALSE {
        return FALSE
    }

    // if nothing registered, leave the function
    if state.registered[code].events == nil {
        return FALSE
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        e: registered_event = state.registered[code].events[i]
        if e.listener == listener_inst && e.callback == on_event {
            // Found event to unregister
            popped_event := Kdarray_pop_at(state.registered[code].events, i)
            return TRUE
        }
    }

    //Not found
    return FALSE
}

/*
 * Fires an event to listeners of the given code. If an event hadler returns
 * TRUE, the event is considered handled and is not passed on to any more listeners.
 * @param code the event code to send.
 * @param sender a pointer to the sender instance. Can be 0/nil.
 * @param data the event context data to send with the event.
 * @return TRUE if the event is successfully sent, FALSE otherwise.
 */
@(private)
Kevent_fire :: proc(code: u16, sender: rawptr, event_context: types.event_context) -> b8 {
   if is_initialized == FALSE {
        return FALSE
    }

    // if nothing registered, leave the function
    if &state.registered[code].events == nil {
        return FALSE
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        e: registered_event = state.registered[code].events[i]
        if e.callback^(code, sender, e.listener, event_context) == TRUE {
            // Event was handled, stop propagation
            return TRUE
        }
    }

    // Not found
    return FALSE
}