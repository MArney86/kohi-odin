#+build !windows
#+build !darwin
package core

import os "core:os"
import fmt "core:fmt"
import mem "core:mem"
import _c "core:c"
import xcb "../../../libs/X11/xcb"
import libc "core:c/libc"
import strings "core:strings"
import xlib "vendor:x11/xlib"
import types "../types"
foreign import lc "system:c"
foreign import xlib_xcb "system:X11-xcb"
foreign import xlib_lib "system:X11"


when ODIN_OS == .Linux {

    // State Structure
    @(private)
    internal_state :: struct {
        display: ^xlib.Display,
        connection: ^xcb.connection_t,
        window: xcb.window_t,
        screen: ^xcb.screen_t,
        wm_protocols: xcb.atom_t,
        wm_delete_win: xcb.atom_t,
    }

    @(private)
    translate_keycode :: proc(x_key: xlib.KeySym) -> (out: types.keys) {
        #partial switch x_key {
            case .XK_BackSpace:
                out = .KEY_BACKSPACE
            
            case .XK_Return:
                out = .KEY_ENTER

            case .XK_Tab:
                out = .KEY_TAB

            // case .XK_Shift: out = .KEY_SHIFT
            // case .XK_Control: out = .KEY_CONTROL

            case .XK_Pause:
                out = .KEY_PAUSE

            case .XK_Caps_Lock:
                out = .KEY_CAPITAL

            case .XK_Escape:
                out = .KEY_ESCAPE
            
            // Not Supported:
            // case: return types.keys.KEY_CONVERT
            // case: return types.keys.KEY_NONCONVERT
            // case: return types.keys.KEY_ACCEPT

            case .XK_Mode_switch:
                out = .KEY_MODECHANGE

            case .XK_space:
                out = .KEY_SPACE
            
            case .XK_Prior:
                out = .KEY_PRIOR

            case .XK_Next:
                out = .KEY_NEXT

            case .XK_End:
                out = .KEY_END

            case .XK_Home:
                out = .KEY_HOME

            case .XK_Left:
                out = .KEY_LEFT

            case .XK_Up:
                out = .KEY_UP
            
            case .XK_Right:
                out = .KEY_RIGHT

            case .XK_Down:
                out = .KEY_DOWN

            case .XK_Select:
                out = .KEY_SELECT

            case .XK_Print:
                out = .KEY_PRINT

            case .XK_Execute:
                out = .KEY_EXECUTE

            // .XK_snapshot: out = .KEY_SNAPSHOT unsupported

            case .XK_Insert:
                out = .KEY_INSERT

            case .XK_Delete:
                out = .KEY_DELETE

            case .XK_Help:
                out = .KEY_HELP

            case .XK_Meta_L:
                out = .KEY_LWIN
            
            case .XK_Meta_R:
                out = .KEY_RWIN

            // case .XK_apps: out = .KEY_APPS
            // case .XK_Sleep: out = .KEYS_SLEEP

            case .XK_KP_0:
                out = .KEY_NUMPAD0
            
            case .XK_KP_1:
                out = .KEY_NUMPAD1

            case .XK_KP_2:
                out = .KEY_NUMPAD2

            case .XK_KP_3:
                out = .KEY_NUMPAD3

            case .XK_KP_4:
                out = .KEY_NUMPAD4

            case .XK_KP_5:
                out = .KEY_NUMPAD5
            
            case .XK_KP_6:
                out = .KEY_NUMPAD6

            case .XK_KP_7:
                out = .KEY_NUMPAD7
        
            case .XK_KP_8:
                out = .KEY_NUMPAD8

            case .XK_KP_9:
                out = .KEY_NUMPAD9

            case .XK_multiply:
                out = .KEY_MULTIPLY

            case .XK_KP_Add:
                out = .KEY_ADD
        
            case .XK_KP_Separator:
                out = .KEY_SEPARATOR

            case .XK_KP_Subtract:
                out = .KEY_SUBTRACT

            case .XK_KP_Decimal:
                out = .KEY_DECIMAL

            case .XK_KP_Divide:
                out = .KEY_DIVIDE
        
            case .XK_F1:
                out = .KEY_F1

            case .XK_F2:
                out = .KEY_F2

            case .XK_F3:
                out = .KEY_F3

            case .XK_F4:
                out = .KEY_F4
            
            case .XK_F5:
                out = .KEY_F5

            case .XK_F6:
                out = .KEY_F6
            
            case .XK_F7:
                out = .KEY_F7
        
            case .XK_F8:
                out = .KEY_F8

            case .XK_F9:
                out = .KEY_F9
            
            case .XK_F10:
                out = .KEY_F10
        
            case .XK_F11:
                out = .KEY_F11
    
            case .XK_F12:
                out = .KEY_F12

            case .XK_F13:
                out = .KEY_F13
            
            case .XK_F14:
                out = .KEY_F14
        
            case .XK_F15:
                out = .KEY_F15
    
            case .XK_F16:
                out = .KEY_F16

            case .XK_F17:
                out = .KEY_F17

            case .XK_F18:
                out = .KEY_F18

            case .XK_F19:
                out = .KEY_F19

            case .XK_F20:
                out = .KEY_F20

            case .XK_F21:
                out = .KEY_F21

            case .XK_F22:
                out = .KEY_F22

            case .XK_F23:
                out = .KEY_F23

            case .XK_F24:
                out = .KEY_F24

            case .XK_Num_Lock:
                out = .KEY_NUMLOCK

            case .XK_Scroll_Lock:
                out = .KEY_SCROLL

            case .XK_KP_Equal:
                out = .KEY_NUMPAD_EQUAL

            case .XK_Shift_L:
                out = .KEY_LSHIFT

            case .XK_Shift_R:
                out = .KEY_RSHIFT

            case .XK_Control_L:
                out = .KEY_LCONTROL

            case .XK_Control_R:
                out = .KEY_RCONTROL

            // case .XK_Menu: out = .KEY_LMENU

            case .XK_Menu:
                out = .KEY_RMENU

            case .XK_semicolon:
                out = .KEY_SEMICOLON

            case .XK_plus:
                out = .KEY_PLUS

            case .XK_comma:
                out = .KEY_COMMA

            case .XK_minus:
                out = .KEY_MINUS

            case .XK_period:
                out = .KEY_PERIOD

            case .XK_slash:
                out = .KEY_SLASH

            case .XK_grave:
                out = .KEY_GRAVE

            case .XK_a,
                 .XK_A:
                out = .KEY_A

            case .XK_b,
                 .XK_B:
                out = .KEY_B

            case .XK_c,
                 .XK_C:
                out = .KEY_C

            case .XK_d,
                 .XK_D:
                out = .KEY_D
                
            case .XK_e,
                 .XK_E:
                out = .KEY_E

            case .XK_f,
                 .XK_F:
                out = .KEY_F

            case .XK_g,
                 .XK_G:
                out = .KEY_G

            case .XK_h,
                 .XK_H:
                out = .KEY_H

            case .XK_i,
                 .XK_I:
                out = .KEY_I

            case .XK_j,
                 .XK_J:
                out = .KEY_J

            case .XK_k,
                 .XK_K:
                out = .KEY_K

            case .XK_l,
                 .XK_L:
                out = .KEY_L

            case .XK_m,
                 .XK_M:
                out = .KEY_M

            case .XK_n,
                 .XK_N:
                out = .KEY_N

            case .XK_o,
                 .XK_O:
                out = .KEY_O

            case .XK_p,
                 .XK_P:
                out = .KEY_P

            case .XK_q,
                 .XK_Q:
                out = .KEY_Q

            case .XK_r,
                 .XK_R:
                out = .KEY_R

            case .XK_s,
                 .XK_S:
                out = .KEY_S

            case .XK_t,
                 .XK_T:
                out = .KEY_T

            case .XK_u,
                 .XK_U:
                out = .KEY_U

            case .XK_v,
                 .XK_V:
                out = .KEY_V

            case .XK_w,
                 .XK_W:
                out = .KEY_W

            case .XK_x,
                 .XK_X:
                out = .KEY_X

            case .XK_y,
                 .XK_Y:
                out = .KEY_Y

            case .XK_z,
                 .XK_Z:
                out = .KEY_Z

            case:
                out = .KEY_UNKNOWN
        }
        return
    }

    @(private)
    platform_startup :: proc(plat_state: ^platform_state, application_name: string, x: i32, y: i32, width: i32, height: i32) -> b8 {
        plat_state.internal_state, _ = mem.alloc(size_of(internal_state), align_of(internal_state))
        state: ^internal_state = cast(^internal_state)(plat_state.internal_state)
        
        // Connect to X server via XCB
        screen_p: i32 = 0
        state.display = xlib.OpenDisplay(nil)
        if state.display == nil {
            KERROR("Failed to open X display")
            return FALSE
        }
        
        state.connection = XGetXCBConnection(state.display)
        
        if xcb.connection_has_error(state.connection) != 0 {
            KERROR("Failed to connect to X server via XCB")
            return FALSE
        }
        
        // Turn off key auto-repeat using XCB
        auto_repeat_off: [1]u32 = {cast(u32)xcb.auto_repeat_mode_t.AUTO_REPEAT_MODE_OFF}
        xcb.change_keyboard_control(state.connection, cast(u32)xcb.kb_t.KB_AUTO_REPEAT_MODE, raw_data(auto_repeat_off[:]))
        
        // Get setup and screen
        setup := xcb.get_setup(state.connection)
        if setup == nil {
            KERROR("Failed to get XCB setup")
            return FALSE
        }
        
        it := xcb.setup_roots_iterator(setup)
        for s: i32 = screen_p; s > 0; s -= 1 {
            xcb.screen_next(&it)
        }
        state.screen = it.data

        KDEBUG("Creating window...")
        
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

        KDEBUG("Window created, setting up window manager protocols...")

        // Set window title
        app_name_len := len(application_name)
        c_name, err := strings.clone_to_cstring(application_name)
        if err != nil {
            KERROR("Failed to convert application name to C string: %s", err)
            return FALSE
        }
        xcb.change_property(
            state.connection,
            cast(u8)xcb.prop_mode_t.PROP_MODE_REPLACE,
            state.window,
            cast(u32)xcb.atom_enum_t.ATOM_WM_NAME,
            cast(u32)xcb.atom_enum_t.ATOM_STRING,
            8,
            cast(u32)app_name_len,
            rawptr(c_name))

        // Set up WM_DELETE_WINDOW protocol
        wm_delete_str: cstring = "WM_DELETE_WINDOW"
        wm_protocols_str: cstring = "WM_PROTOCOLS"

        wm_delete_cookie := xcb.intern_atom(
            state.connection,
            0,
            cast(u16)libc.strlen(wm_delete_str),
            wm_delete_str)
            
        wm_protocols_cookie := xcb.intern_atom(
            state.connection,
            0,
            cast(u16)libc.strlen(wm_protocols_str),
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
            KERROR("Failed to get atom replies")
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
        if wm_delete_reply != nil {
            libc.free(wm_delete_reply)
        }
        if wm_protocols_reply != nil {
            libc.free(wm_protocols_reply)
        }
        // Map the window (make it visible)
        xcb.map_window(state.connection, state.window)
        
        // Flush all requests to X server
        stream_result := xcb.flush(state.connection)
        if stream_result <= 0 {
            KERROR("Failed to flush XCB stream: %d", stream_result)
            return FALSE
        }

        KDEBUG("Window should now be visible!")
        
        return TRUE
    }

    @(private)
    platform_shutdown :: proc(plat_state: ^platform_state) {
        state: ^internal_state = cast(^internal_state)(plat_state.internal_state)

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
                        libc.free(event)
                        return FALSE // Indicate shutdown
                    }
                
                case cast(u8)xcb.KEY_PRESS, cast(u8)xcb.KEY_RELEASE:
                    // Handle key events
                    kb_event: ^xcb.key_press_event_t = cast(^xcb.key_press_event_t)event
                    pressed: b8 = event.response_type == xcb.KEY_PRESS;
                    code: xcb.keycode_t = kb_event.detail
                    shift_mask := (kb_event.state & u16(xlib.KeyMask.ShiftMask)) != 0
                    
                    if state.display == nil {
                        KERROR("Display is nil in key event handler!")
                        break
                    }
                    
                    key_sym: xlib.KeySym = XkbKeycodeToKeysym(state.display, code, 0, _c.uint(shift_mask))
                    key: types.keys = translate_keycode(key_sym)

                    //pass to input subsystem for processing
                    input_process_key(key, pressed)

                case cast(u8)xcb.BUTTON_PRESS, cast(u8)xcb.BUTTON_RELEASE:
                    // Handle mouse button events
                    mouse_event: ^xcb.button_press_event_t  = cast(^xcb.button_press_event_t)event;
                    pressed: b8 = event.response_type == cast(u8)xcb.BUTTON_PRESS;
                    mouse_button: types.buttons = .BUTTON_MAX_BUTTONS
                    switch (mouse_event.detail) {
                        case cast(u8)xcb.button_index_t.BUTTON_INDEX_1:
                            mouse_button = .BUTTON_LEFT;
                        case cast(u8)xcb.button_index_t.BUTTON_INDEX_2:
                            mouse_button = .BUTTON_MIDDLE;
                        case cast(u8)xcb.button_index_t.BUTTON_INDEX_3:
                            mouse_button = .BUTTON_RIGHT;
                    }
                    
                    if mouse_button != .BUTTON_MAX_BUTTONS {
                        KDEBUG("Mouse button %v %s", mouse_button, pressed ? "pressed" : "released")
                        input_process_button(mouse_button, pressed)
                    }
                    
                case cast(u8)xcb.MOTION_NOTIFY:
                    // Handle mouse motion events
                    motion_event := cast(^xcb.motion_notify_event_t)event
                    input_process_mouse_move(motion_event.event_x, motion_event.event_y)

                case cast(u8)xcb.CONFIGURE_NOTIFY:
                    // Handle window resize/move events
                    // configure_event := cast(^xcb.configure_notify_event_t)event
                    // TODO: Process configure events

                case:
                    // Handle other events
            }

            // Free event
            if event != nil {
                libc.free(event)
            }
        }

        return TRUE
    }

    @(private)
    platform_console_write :: proc(message: string, colour: u8) {
        // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
        colour_strings := [6]string{"0;41", "1;31", "1;33", "1;32", "1;34", "1;30"}
        
        if colour < len(colour_strings) {
            fmt.printf("\033[%sm%s\033[0m", colour_strings[colour], message)
            os.flush(os.stdout)
        } else {
            fmt.printf(message)
            os.flush(os.stdout)
        }
    }

    @(private)
    platform_console_write_error :: proc(message: string, colour: u8) {
        temp := colour
        // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
        colour_strings := [6]string{"0;41", "1;31", "1;33", "1;32", "1;34", "1;30"}
        
        if colour < len(colour_strings) {
            fmt.eprintf("\033[%sm%s\033[0m", colour_strings[colour], message)
            os.flush(os.stderr)
        } else {
            fmt.eprintf(message)
            os.flush(os.stderr)
        }
    }

    @(private)
    platform_get_absolute_time :: proc() -> f64 {
        now: libc.timespec
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

        
@(default_calling_convention="c")
foreign lc {
    clock_gettime :: proc(clk_id: _c.int, tp: ^libc.timespec) -> _c.int ---
}

@(default_calling_convention="c")
foreign xlib_xcb {
    XGetXCBConnection :: proc(dpy: ^xlib.Display) -> ^xcb.connection_t ---
}

@(default_calling_convention="c")
foreign xlib_lib {
    XkbKeycodeToKeysym :: proc(dpy: ^xlib.Display, kc: xlib.KeyCode, group: _c.uint, level: _c.uint) -> xlib.KeySym ---
}