package event

import types "../../types"
import logger "../logger"
import memory "../memory"
import darray "../../containers/darray"
import runtime "base:runtime"


MAX_MESSAGE_CODES :: 16384
initialized: bool = false

registered_event :: struct {
    listener: rawptr,
    callback: types.PFN_on_event,
}

code_entry :: struct {
    events: ^[dynamic]registered_event,
}

system_state :: struct {
    registered: [MAX_MESSAGE_CODES]code_entry,
}

state: system_state

initialize :: proc() -> bool {
    if initialized == true {
        return false
    }
    initialized = false
    memory.zero_memory(&state, size_of(state))
    initialized = true;
    
    return true
}

shutdown :: proc() {
    for i: u16; i < MAX_MESSAGE_CODES; i += 1 {
        if state.registered[i].events != nil {
            darray.Delete(state.registered[i].events, typeid_of(registered_event));
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
register :: proc(code: u16, listener_inst: rawptr, on_event: types.PFN_on_event) -> bool {
    if initialized == false {
        return false
    }

    if state.registered[code].events == nil {
        array := cast(^[dynamic]registered_event)darray.Make(registered_event)
        state.registered[code].events = array
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        if state.registered[code].events[i].listener == listener_inst {
            //TODO: Warn
            return false
        }
    }

    event: registered_event
    event.listener = listener_inst
    event.callback = on_event
    if !darray.push(cast(rawptr)state.registered[code].events, registered_event, cast(rawptr)&event) {
        logger.ERROR("Failed to register event listener for code %d", code)
        return false
    }
    return true
}

/*
 * Unregister a previously registered event listener/callback combo.
 * @param code the event code to stop listening for.
 * @param listener a pointer to the listener instance. Can be 0/nil.
 * @param on_event the callback function pointer to be unregistered.
 * @return TRUE if the event listener is successfully unregistered, FALSE otherwise.
 */
unregister :: proc(code: u16, listener_inst: rawptr, on_event: types.PFN_on_event) -> bool {
     if initialized == false {
        return false
    }

    // if nothing registered, leave the function
    if state.registered[code].events == nil {
        return false
    }

    if len(state.registered[code].events) == 0 {
        // No listeners registered for this event, which is okay
        return false
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        e: registered_event = state.registered[code].events[i]
        if e.listener == listener_inst && e.callback == on_event {
            // Found event to unregister
            popped_event: registered_event
            darray.pop_at(state.registered[code].events, registered_event, i, &popped_event)
            return true
        }
    }

    //Not found
    return false
}

/*
 * Fires an event to listeners of the given code. If an event hadler returns
 * TRUE, the event is considered handled and is not passed on to any more listeners.
 * @param code the event code to send.
 * @param sender a pointer to the sender instance. Can be 0/nil.
 * @param data the event context data to send with the event.
 * @return TRUE if the event is successfully sent, FALSE otherwise.
 */
fire :: proc(code: u16, sender: rawptr, event_context: types.event_context) -> bool {
   if initialized == false {
        return false
    }

    // if nothing registered, leave the function
    if state.registered[code].events == nil {
        // No listeners registered for this event, which is okay
        return false
    }

    registered_count: u64 = cast(u64)len(state.registered[code].events)
    for i: u64; i < registered_count; i += 1 {
        e: registered_event = state.registered[code].events[i]
        if e.callback == nil {
            logger.ERROR("Event callback is nil for code %d at index %d", code, i)
            continue
        }
        if e.callback^(code, sender, e.listener, event_context) == true {
            // Event was handled, stop propagation
            return true
        }
    }

    // Not found
    return false
}