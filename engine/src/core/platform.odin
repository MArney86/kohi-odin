package Kcore

import mem "core:mem"
import win32 "core:sys/windows"
import utf16 "core:unicode/utf16"
import builtin "base:builtin"

// Platform state structure
platform_state :: struct {
    internal_state: rawptr,
}

cstring_to_utf16 :: proc(str: cstring) -> ^u16 {
    str_odin := string(str)
    utf16_slice := make([]u16, len(str_odin) * 2)
    utf16.encode_string(utf16_slice, str_odin) // Use encode_string to fill the buffer
    return &utf16_slice[0]
}

string_to_utf16 :: proc(str: string) -> ^u16 {
    utf16_slice := make([]u16, len(str) * 2)
    utf16.encode_string(utf16_slice, str)
    return &utf16_slice[0]
}

// Windows layer
when ODIN_OS == .Windows {
    // Use pure Odin and core:system/windows for Win32 API

    internal_state :: struct {
        h_instance: win32.HINSTANCE,
        h_wnd:      win32.HWND,
    }

    //clock
    clock_frequency: f64
    start_time: win32.LARGE_INTEGER


    // Window message callback (CALLBACK = __stdcall)
    win32_process_message :: proc "stdcall"(hwnd: win32.HWND, msg: u32, w_param: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
        switch msg {
            case win32.WM_ERASEBKGND:
                // Notify the OS that erasing will be handled by the application to prevent flicker
                return 1
            case win32.WM_CLOSE:
                //TODO: Fire an event for the application to quit.
                return 0
            case win32.WM_DESTROY:
                // Post a quit message to the message queue
                win32.PostQuitMessage(0)
                return 0
            case win32.WM_SIZE:{
                // Get the updated size
                //r := win32.RECT{}
                //win32.GetClientRect(hwnd, &r)
                //width: u32 = r.right - r.left
                //height: u32 = r.bottom - r.top

                //TODO: Fire an event for window resize.
            }
            case win32.WM_KEYDOWN, win32.WM_SYSKEYDOWN, win32.WM_KEYUP, win32.WM_SYSKEYUP: {
                // key pressed/released
                //pressed: b8 = (msg == win32.WM_KEYDOWN || msg == win32.WM_SYSKEYDOWN)
                //TODO: input processing
            }
            case win32.WM_MOUSEMOVE: {
                // mouse move
                //x_position: i32 = win32.GET_X_LPARAM(l_param)
                //y_position: i32 = win32.GET_Y_LPARAM(l_param)
                //TODO: input processing.
            }
            case win32.WM_MOUSEWHEEL: {
                //z_delta: i32 = win32.GET_WHEEL_DELTA_WPARAM(w_param)
                //if z_delta != 0 {
                    // flatten the input to an OS-independent value
                    //z_delta =  (z_delta < 0) ? -1 : 1
                    //TODO: input processing.
            }
            case win32.WM_LBUTTONDOWN, win32.WM_MBUTTONDOWN, win32.WM_RBUTTONDOWN, win32.WM_LBUTTONUP, win32.WM_MBUTTONUP, win32.WM_RBUTTONUP: {
                // pressed: b8 = (msg == win32.WM_LBUTTONDOWN || msg == win32.WM_MBUTTONDOWN || msg == win32.WM_RBUTTONDOWN)
                //TODO: input processing.
            }
        }

        return win32.DefWindowProcW(hwnd, msg, w_param, lparam)
    
    }
    
    // Platform-based application state functions

    platform_startup :: proc(plat_state: ^platform_state, application_name: string, x: i32, y: i32, width: i32, height: i32) -> b8 {
        // Allocate memory for internal state using Odin allocator
        plat_state.internal_state, _ = mem.alloc(size_of(internal_state), align_of(internal_state))
        // Cast raw pointer and initialize fields
        state := cast(^internal_state)(plat_state.internal_state)
        state.h_instance = cast(win32.HANDLE)(win32.GetModuleHandleW(nil))

        // Load default icon
        icon: win32.HICON = win32.LoadIconW(state.h_instance, string_to_utf16("IDI_APPLICATION"))

        // Register window class
        wc := win32.WNDCLASSW{}
        // Setup window class
        wc.style = win32.CS_DBLCLKS
        wc.lpfnWndProc = win32_process_message
        wc.cbClsExtra = 0
        wc.cbWndExtra = 0
        wc.hInstance = state.h_instance
        wc.hIcon = icon
        wc.hCursor = win32.LoadCursorW(nil, string_to_utf16("IDC_ARROW"))
        wc.hbrBackground = nil
        wc.lpszClassName = string_to_utf16("kohi_window_class")
        if win32.RegisterClassW(&wc) == 0 {
            win32.MessageBoxW(nil, string_to_utf16("Window registration failed!"), string_to_utf16("Error"), win32.MB_ICONEXCLAMATION | win32.MB_OK)
            return FALSE
        }
        // create window
        client_x: i32 = x
        client_y: i32 = y
        client_width: i32 = width
        client_height: i32 = height

        window_x: i32 = client_x
        window_y: i32 = client_y
        window_width: i32 = client_width
        window_height: i32 = client_height

        win32.ShowWindow(state.h_wnd, win32.SW_SHOW)
        win32.UpdateWindow(state.h_wnd)

        window_style: u32 = win32.WS_OVERLAPPED | win32.WS_SYSMENU | win32.WS_CAPTION
        window_ex_style: u32 = win32.WS_EX_APPWINDOW

        window_style |= win32.WS_MAXIMIZEBOX
        window_style |= win32.WS_MINIMIZEBOX
        window_style |= win32.WS_THICKFRAME

        //Obtain the border size
        border_rect := win32.RECT{0, 0, 0, 0}
        win32.AdjustWindowRectEx(&border_rect, window_style, FALSE, window_ex_style)

        //In this case, the border rectangle is negative
        window_x += border_rect.left
        window_y += border_rect.top

        //Grow by the size of the OS border
        window_width += border_rect.right - border_rect.left
        window_height += border_rect.bottom - border_rect.top
        
        handle: win32.HWND = win32.CreateWindowExW(
            window_ex_style,
            string_to_utf16("kohi_window_class"),
            string_to_utf16(application_name),
            window_style,
            window_x, window_y,
            window_width, window_height,
            nil, nil, state.h_instance, nil)
        
        if handle == nil {
            win32.MessageBoxW(nil, string_to_utf16("Window creation failed!"), string_to_utf16("Error"), win32.MB_ICONEXCLAMATION | win32.MB_OK)

            KFATAL("Window creation failed!")
            return FALSE
        } else {
            state.h_wnd = handle
        }

        // Show  the window
        should_activate : b32 = TRUE //TODO: if the window should not accept input, this should be FALSE
        show_window_command_flags: i32 = should_activate ? win32.SW_SHOW : win32.SW_SHOWNOACTIVATE
        //if initially minimized, use SW_MINIMIZE: SW_SHOWMINNOACTIVE
        //if initially maximized, use SW_MAXIMIZED: SW_MAXIMIZE
        win32.ShowWindow(state.h_wnd, show_window_command_flags)

        // Clock setup
        frequency: win32.LARGE_INTEGER
        win32.QueryPerformanceFrequency(&frequency)
        // Compute seconds-per-count using Odin cast
        clock_frequency = 1.0 / f64(frequency)
        win32.QueryPerformanceCounter(&start_time)

        return TRUE
    }

    platform_shutdown :: proc(plat_state: ^platform_state) {
        state := cast(^internal_state)(plat_state.internal_state)

        if state.h_wnd != nil {
            // Destroy the window
            win32.DestroyWindow(state.h_wnd)
            state.h_wnd = nil
        }
    }

    platform_pump_messages :: proc(plat_state: ^platform_state) -> b8 {
        message := win32.MSG{}
        // Process all pending Windows messages
        for win32.PeekMessageW(&message, nil, 0, 0, win32.PM_REMOVE) {
            win32.TranslateMessage(&message)
            win32.DispatchMessageW(&message)
        }

        return TRUE
    }

    //Platform-based memory management functions

    platform_allocate :: proc(size: u64, aligned: b8) -> rawptr {
        new_mem, _ := mem.alloc(cast(int)size)
        return new_mem
    }

    platform_free :: proc(block: rawptr, aligned: b8) {
        mem.free(block)
    }

    platform_zero_memory :: proc(block: rawptr, size: u64) -> rawptr {
        return mem.zero(block, cast(int)size)
    }

    platform_copy_memory :: proc(dest: rawptr, source: rawptr, size: u64) -> rawptr {
        return mem.copy(dest, source, cast(int)size)
    }

    platform_set_memory :: proc(dest: rawptr, value: u8, size: u64) -> rawptr {
        return mem.set(dest, value, cast(int)size)
    }

    // Platform-based console functions

    platform_console_write :: proc(message: string, colour: u8) {
        console_handle: win32.HANDLE = win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
        if console_handle == nil {
            KFATAL("Invalid console handle")
            return
        }
        // FATAL, ERROR, WARN, INFO, DEBUG, TRACE
        levels := [6]u16{64, 4, 6, 2, 1, 8}
        win32.SetConsoleTextAttribute(console_handle, levels[colour])

        win32.OutputDebugStringW(string_to_utf16(message))
        length: int = len(message)
        number_written: win32.LPDWORD = cast(win32.LPDWORD)(nil)
        win32.WriteConsoleW(console_handle, string_to_utf16(message), cast(win32.DWORD)length, &number_written^, nil)
    }

    platform_console_write_error :: proc(message: string, colour: u8) {
        console_handle: win32.HANDLE = win32.GetStdHandle(win32.STD_ERROR_HANDLE)
        if console_handle == nil {
            KFATAL("Invalid console handle")
            return
        }
        // FATAL, ERROR, WARN, INFO, DEBUG, TRACE
        levels := [6]u16{64, 4, 6, 2, 1, 8}
        win32.SetConsoleTextAttribute(console_handle, levels[colour])

        win32.OutputDebugStringW(string_to_utf16(message))
        length: int = len(message)
        number_written: win32.LPDWORD = cast(win32.LPDWORD)(nil)
        win32.WriteConsoleW(console_handle, string_to_utf16(message), cast(win32.DWORD)length, &number_written^, nil)
    }

    // Platform-based time functions
    platform_get_absolute_time :: proc() -> f64 {
        now_time: win32.LARGE_INTEGER
        win32.QueryPerformanceCounter(&now_time)
        return cast(f64)now_time * clock_frequency
    }

    //Sleep on the thread for the provided ms. Thsi blocks the tread.
    //Should only be used for giving time back to the OS for unused update power.
    //Therefore it is not exported.
    platform_sleep :: proc(ms: u64) {
        win32.Sleep(cast(win32.DWORD)ms)
    }
}

when ODIN_OS == .Linux {
    // Platform-based application state functions

    platform_startup :: proc(plat_state: ^platform_state, application_name: cstring, x: i32, y: i32, width: i32, height: i32) -> b8 {
        // Stub implementation: always succeed
        return TRUE
    }

    platform_shutdown :: proc(plat_state: ^platform_state) {
        // Stub implementation: nothing to clean up
    }

    platform_pump_messages :: proc(plat_state: ^platform_state) -> b8 {
        // Stub implementation: always return TRUE
        return TRUE
    }

    //Platform-based memory management functions

    perform_allocate :: proc(size: u64, aligned: b8) -> rawptr {
        return rawptr(0)
    }

    platform_free :: proc(block: rawptr, aligned: b8) {
        // Stub implementation: do nothing
    }

    platform_zero_memory :: proc(block: rawptr, size: u64) -> rawptr{
        return rawptr(0)
    }

    platform_copy_memory :: proc(dest: rawptr, source: rawptr, size: u64) -> rawptr {
        return rawptr(0)
    }

    platform_set_memory :: proc(dest: rawptr, value: u8, size: u64) -> rawptr {
        return rawptr(0)
    }

    // Platform-based console functions

    platform_console_write :: proc(message: cstring, colour: u8) {
        // Stub implementation: do nothing
    }

    platform_console_write_error :: proc(message: cstring, colour: u8) {
        // Stub implementation: do nothing
    }

    // Platform-based time functions
    platform_get_absolute_time :: proc() -> u64 {
        // Stub implementation: return 0
        return 0
    }

    //Sleep on the thread for the provided ms. Thsi blocks the tread.
    //Should only be used for giving time back to the OS for unused update power.
    //Therefore it is not exported.
    platform_sleep :: proc(ms: u64) {
        // Stub implementation: do nothing
    }
}