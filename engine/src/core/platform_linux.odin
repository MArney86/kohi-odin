#+build !windows
#+build !darwin
package Kcore

import mem "core:mem"
import _c "core:c"
import gnulinux "core:sys/linux"
import x11 "vendor:x11/xlib"
import xcb "../../../libs/X11/xcb"
import "core:time"
import corelibc "core:c/libc"

when ODIN_OS == .Linux {

    // State Structure
    @(private)
    internal_state :: struct {
        connection: ^xcb.connection_t,
        window: xcb.window_t,
        screen: ^xcb.screen_t,
        wm_protocols: xcb.atom_t,
        wm_delete_win: xcb.atom_t,
    }

    @(private)
    platform_startup :: proc(plat_state: ^platform_state, application_name: cstring, x: i32, y: i32, width: i32, height: i32) -> b8 {
        corelibc.printf("[DEBUG] platform_startup called\n")
        corelibc.fflush(nil)

        plat_state.internal_state, _ = mem.alloc(size_of(internal_state), align_of(internal_state))
        state: ^internal_state = cast(^internal_state)(plat_state.internal_state)
        
        // Connect to X server via XCB
        screen_p: i32 = 0
        state.connection = xcb.connect(nil, &screen_p)
        
        if xcb.connection_has_error(state.connection) != 0 {
            corelibc.printf("[ERROR] Failed to connect to X server via XCB\n")
            return FALSE
        }
        
        // Turn off key auto-repeat using XCB
        auto_repeat_off: [1]u32 = {cast(u32)xcb.auto_repeat_mode_t.AUTO_REPEAT_MODE_OFF}
        xcb.change_keyboard_control(state.connection, cast(u32)xcb.kb_t.KB_AUTO_REPEAT_MODE, raw_data(auto_repeat_off[:]))
        
        // Get setup and screen
        setup := xcb.get_setup(state.connection)
        if setup == nil {
            corelibc.printf("[ERROR] Failed to get XCB setup\n")
            return FALSE
        }
        
        it := xcb.setup_roots_iterator(setup)
        for s: i32 = screen_p; s > 0; s -= 1 {
            xcb.screen_next(&it)
        }
        state.screen = it.data

        corelibc.printf("[DEBUG] Creating window...\n")
        corelibc.fflush(nil)

        // Generate window ID
        state.window = xcb.generate_id(state.connection)
        
        // Set up event mask and values
        event_mask: u32 = cast(u32)xcb.cw_t.CW_BACK_PIXEL | cast(u32)xcb.cw_t.CW_EVENT_MASK
        event_values: u32 = cast(u32)xcb.event_mask_t.EVENT_MASK_BUTTON_PRESS | cast(u32)xcb.event_mask_t.EVENT_MASK_BUTTON_RELEASE |
                           cast(u32)xcb.event_mask_t.EVENT_MASK_KEY_PRESS | cast(u32)xcb.event_mask_t.EVENT_MASK_KEY_RELEASE |
                           cast(u32)xcb.event_mask_t.EVENT_MASK_EXPOSURE | cast(u32)xcb.event_mask_t.EVENT_MASK_POINTER_MOTION |
                           cast(u32)xcb.event_mask_t.EVENT_MASK_STRUCTURE_NOTIFY

        value_list: [2]u32 = {state.screen.black_pixel, event_values}
        
        // Create the window
        xcb.create_window(
            state.connection,
            cast(u8)xcb.COPY_FROM_PARENT,      // depth
            state.window,                      // window ID
            state.screen.root,                 // parent window
            cast(i16)x,                       // x position
            cast(i16)y,                       // y position  
            cast(u16)width,                   // width
            cast(u16)height,                  // height
            0,                                // border width
            cast(u16)xcb.window_class_t.WINDOW_CLASS_INPUT_OUTPUT, // class
            state.screen.root_visual,         // visual
            event_mask,                       // value mask
            raw_data(value_list[:]))          // value list

        corelibc.printf("[DEBUG] Window created, setting up window manager protocols...\n")
        corelibc.fflush(nil)

        // Set window title
        app_name_len := corelibc.strlen(application_name)
        xcb.change_property(
            state.connection,
            cast(u8)xcb.prop_mode_t.PROP_MODE_REPLACE,
            state.window,
            cast(u32)xcb.atom_enum_t.ATOM_WM_NAME,
            cast(u32)xcb.atom_enum_t.ATOM_STRING,
            8,
            cast(u32)app_name_len,
            raw_data(cast(string)application_name))

        // Set up WM_DELETE_WINDOW protocol
        wm_delete_str: cstring = "WM_DELETE_WINDOW"
        wm_protocols_str: cstring = "WM_PROTOCOLS"

        wm_delete_cookie := xcb.intern_atom(
            state.connection,
            0,
            cast(u16)corelibc.strlen(wm_delete_str),
            wm_delete_str)
            
        wm_protocols_cookie := xcb.intern_atom(
            state.connection,
            0,
            cast(u16)corelibc.strlen(wm_protocols_str),
            wm_protocols_str)

        wm_delete_reply := xcb.intern_atom_reply(
            state.connection,
            wm_delete_cookie,
            nil)
            
        wm_protocols_reply := xcb.intern_atom_reply(
            state.connection,
            wm_protocols_cookie,
            nil)

        if wm_delete_reply == nil || wm_protocols_reply == nil {
            corelibc.printf("[ERROR] Failed to get atom replies\n")
            return FALSE
        }

        state.wm_delete_win = wm_delete_reply.atom
        state.wm_protocols = wm_protocols_reply.atom

        xcb.change_property(
            state.connection,
            cast(u8)xcb.prop_mode_t.PROP_MODE_REPLACE,
            state.window,
            wm_protocols_reply.atom,
            cast(u32)xcb.atom_enum_t.ATOM_ATOM,
            32,
            1,
            &wm_delete_reply.atom)

        // Free the atom replies
        corelibc.free(wm_delete_reply)
        corelibc.free(wm_protocols_reply)
        
        // Map the window (make it visible)
        xcb.map_window(state.connection, state.window)
        
        // Flush all requests to X server
        stream_result := xcb.flush(state.connection)
        if stream_result <= 0 {
            corelibc.printf("[ERROR] Failed to flush XCB stream: %d\n", stream_result)
            return FALSE
        }

        corelibc.printf("[DEBUG] Window should now be visible!\n")
        corelibc.fflush(nil)
        
        return TRUE
    }

    @(private)
    platform_shutdown :: proc(plat_state: ^platform_state) {
        state := cast(^internal_state)(plat_state.internal_state)

        if state != nil {
            // Restore auto-repeat
            auto_repeat_default: [1]u32 = {cast(u32)xcb.auto_repeat_mode_t.AUTO_REPEAT_MODE_DEFAULT}
            xcb.change_keyboard_control(state.connection, cast(u32)xcb.kb_t.KB_AUTO_REPEAT_MODE, raw_data(auto_repeat_default[:]))

            if state.connection != nil {
                xcb.disconnect(state.connection)
            }

            mem.free(plat_state.internal_state)
            plat_state.internal_state = nil
        }
    }

    @(private)
    platform_pump_messages :: proc(plat_state: ^platform_state) -> b8 {
        state := cast(^internal_state)(plat_state.internal_state)
        
        if state == nil || state.connection == nil {
            return TRUE
        }

        // Poll for XCB events
        for {
            event := xcb.poll_for_event(state.connection)
            if event == nil {
                break // No more events
            }

            // Process events based on response type
            switch event.response_type & ~cast(u8)0x80 {
                case cast(u8)xcb.CLIENT_MESSAGE:
                    // Handle window close
                    client_event := cast(^xcb.client_message_event_t)event
                    if client_event.data.data32[0] == state.wm_delete_win {
                        corelibc.free(event)
                        return FALSE // Indicate shutdown
                    }
                
                case cast(u8)xcb.KEY_PRESS, cast(u8)xcb.KEY_RELEASE:
                    // Handle key events
                    // key_event := cast(^xcb.key_press_event_t)event
                    // TODO: Process key events

                case cast(u8)xcb.BUTTON_PRESS, cast(u8)xcb.BUTTON_RELEASE:
                    // Handle mouse button events
                    // button_event := cast(^xcb.button_press_event_t)event
                    // TODO: Process button events

                case cast(u8)xcb.MOTION_NOTIFY:
                    // Handle mouse motion events
                    // motion_event := cast(^xcb.motion_notify_event_t)event
                    // TODO: Process motion events

                case cast(u8)xcb.CONFIGURE_NOTIFY:
                    // Handle window resize/move events
                    // configure_event := cast(^xcb.configure_notify_event_t)event
                    // TODO: Process configure events

                case:
                    // Handle other events
            }

            // Free event
            corelibc.free(event)
        }

        return TRUE
    }

    @(private)
    platform_console_write :: proc(message: string, colour: u8) {
        // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
        colour_strings := [6]cstring{"0;41", "1;31", "1;33", "1;32", "1;34", "1;30"}
        
        if colour < len(colour_strings) {
            corelibc.printf("\033[%sm%s\033[0m", colour_strings[colour], raw_data(message))
        } else {
            corelibc.printf("%s", raw_data(message))
        }
    }

    @(private)
    platform_console_write_error :: proc(message: string, colour: u8) {
        // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
        colour_strings := [6]cstring{"0;41", "1;31", "1;33", "1;32", "1;34", "1;30"}
        
        if colour < len(colour_strings) {
            corelibc.fprintf(corelibc.stderr, "\033[%sm%s\033[0m", colour_strings[colour], raw_data(message))
        } else {
            corelibc.fprintf(corelibc.stderr, "%s", raw_data(message))
        }
    }

    @(private)
    platform_get_absolute_time :: proc() -> f64 {
        now: corelibc.timespec
        CLOCK_MONOTONIC :: 1  // Linux constant for monotonic clock
        result := clock_gettime(CLOCK_MONOTONIC, &now)
        if result != 0 {
            // Error occurred
            return 0.0
        }

        return cast(f64)now.tv_sec + cast(f64)now.tv_nsec / 1e9
    }
}

// Import clock_gettime from libc
foreign import libc "system:c"
        
@(default_calling_convention="c")
foreign libc {
    clock_gettime :: proc(clk_id: _c.int, tp: ^corelibc.timespec) -> _c.int ---
}
