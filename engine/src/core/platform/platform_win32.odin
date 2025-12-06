#+build !linux
#+build !darwin
package platform

import mem "core:mem"
import win32 "core:sys/windows"
import runtime "base:runtime"
import types "../../types"
import input "../input"
import console "../console"
//Helpers for string conversions between UTF-8 and UTF-16 on Windows.
import str "../string"
import vk "vendor:vulkan/dynamic"
import event "../event"

// Windows layer
when ODIN_OS == .Windows {
    internal_state :: struct {
        h_instance: win32.HINSTANCE,
        h_wnd:      win32.HWND,
        surface: vk.SurfaceKHR
    }

    //clock
    clock_frequency: f64
    start_time: win32.LARGE_INTEGER


    // Window message callback (CALLBACK = __stdcall)
    @(private)
    win32_process_message :: proc "stdcall"(hwnd: win32.HWND, msg: u32, w_param: win32.WPARAM, l_param: win32.LPARAM) -> win32.LRESULT {
        context = runtime.default_context()
        switch msg {
            case win32.WM_ERASEBKGND:
                // Notify the OS that erasing will be handled by the application to prevent flicker
                return 1
            case win32.WM_CLOSE:
                data: types.event_context = {}
                event.fire(cast(u16)types.system_event_codes.EVENT_CODE_APPLICATION_QUIT, nil, data)
                return cast(win32.LRESULT)true
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
                pressed: bool = (msg == win32.WM_KEYDOWN || msg == win32.WM_SYSKEYDOWN)
                key: types.keys = cast(types.keys)w_param
                input.process_key(key, pressed)
            }
            case win32.WM_MOUSEMOVE: {
                // mouse move
                x_position: i32 = win32.GET_X_LPARAM(l_param)
                y_position: i32 = win32.GET_Y_LPARAM(l_param)
                input.process_mouse_move(i16(x_position), i16(y_position))
            }
            case win32.WM_MOUSEWHEEL: {
                z_delta: i32 = cast(i32)win32.GET_WHEEL_DELTA_WPARAM(w_param)
                if z_delta != 0 {
                    //flatten the input to an OS-independent value
                    z_delta =  (z_delta < 0) ? -1 : 1
                    input.process_mouse_wheel(i8(z_delta))
                }
            }
                    
            case win32.WM_LBUTTONDOWN, win32.WM_MBUTTONDOWN, win32.WM_RBUTTONDOWN, win32.WM_LBUTTONUP, win32.WM_MBUTTONUP, win32.WM_RBUTTONUP: {
                pressed: bool = (msg == win32.WM_LBUTTONDOWN || msg == win32.WM_MBUTTONDOWN || msg == win32.WM_RBUTTONDOWN)
                mouse_button: types.buttons = .BUTTON_MAX_BUTTONS
                switch msg {
                    case win32.WM_LBUTTONDOWN, win32.WM_LBUTTONUP:
                        mouse_button = .BUTTON_LEFT
                    case win32.WM_MBUTTONDOWN, win32.WM_MBUTTONUP:
                        mouse_button = .BUTTON_MIDDLE
                    case win32.WM_RBUTTONDOWN, win32.WM_RBUTTONUP:
                        mouse_button = .BUTTON_RIGHT
                }

                if mouse_button != .BUTTON_MAX_BUTTONS {
                    input.process_button(mouse_button, pressed)
                }
            }
        }

        return win32.DefWindowProcW(hwnd, msg, w_param, l_param)
    
    }
    
    // Platform-based application state functions

    startup :: proc(plat_state: ^types.platform_state, application_name: string, x: i32, y: i32, width: i32, height: i32) -> b8 {
        // Allocate memory for internal state using Odin allocator
        plat_state.internal_state, _ = mem.alloc(size_of(internal_state), align_of(internal_state))
        // Cast raw pointer and initialize fields
        state := cast(^internal_state)(plat_state.internal_state)
        state.h_instance = cast(win32.HANDLE)(win32.GetModuleHandleW(nil))

        // Load default icon
        icon: win32.HICON = win32.LoadIconW(state.h_instance, str.str_to_wstring("IDI_APPLICATION"))

        // Register window class
        wc := win32.WNDCLASSW{}
        // Setup window class
        wc.style = win32.CS_DBLCLKS
        wc.lpfnWndProc = win32_process_message
        wc.cbClsExtra = 0
        wc.cbWndExtra = 0
        wc.hInstance = state.h_instance
        wc.hIcon = icon
        wc.hCursor = win32.LoadCursorW(nil, str.str_to_wstring("IDC_ARROW"))
        wc.hbrBackground = nil
        wc.lpszClassName = str.str_to_wstring("kohi_window_class")
        if win32.RegisterClassW(&wc) == 0 {
            win32.MessageBoxW(nil, str.str_to_wstring("Window registration failed!"), str.str_to_wstring("Error"), win32.MB_ICONEXCLAMATION | win32.MB_OK)
            return false
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
        win32.AdjustWindowRectEx(&border_rect, window_style, false, window_ex_style)

        //In this case, the border rectangle is negative
        window_x += border_rect.left
        window_y += border_rect.top

        //Grow by the size of the OS border
        window_width += border_rect.right - border_rect.left
        window_height += border_rect.bottom - border_rect.top
        
        handle: win32.HWND = win32.CreateWindowExW(
            window_ex_style,
            str.str_to_wstring("kohi_window_class"),
            str.str_to_wstring(application_name),
            window_style,
            window_x, window_y,
            window_width, window_height,
            nil, nil, state.h_instance, nil)
        
        if handle == nil {
            win32.MessageBoxW(nil, str.str_to_wstring("Window creation failed!"), str.str_to_wstring("Error"), win32.MB_ICONEXCLAMATION | win32.MB_OK)
            console.write_error("Window creation failed!", 0)
            return false
        } else {
            state.h_wnd = handle
        }

        // Show  the window
        should_activate : b32 = true //TODO: if the window should not accept input, this should be FALSE
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

        return true
    }

    shutdown :: proc(plat_state: ^types.platform_state) {
        state := cast(^internal_state)(plat_state.internal_state)

        if state.h_wnd != nil {
            // Destroy the window
            win32.DestroyWindow(state.h_wnd)
            state.h_wnd = nil
        }
    }

    pump_messages :: proc(plat_state: ^types.platform_state) -> bool {
        message := win32.MSG{}
        // Process all pending Windows messages
        for win32.PeekMessageW(&message, nil, 0, 0, win32.PM_REMOVE) {
            win32.TranslateMessage(&message)
            win32.DispatchMessageW(&message)
        }

        return true
    }

    // Platform-based time functions
    get_absolute_time :: proc() -> f64 {
        now_time: win32.LARGE_INTEGER
        win32.QueryPerformanceCounter(&now_time)
        return cast(f64)now_time * clock_frequency
    }

    get_required_extension_names :: proc(names_darray: ^[dynamic]cstring) {
        append(names_darray, cstring(vk.KHR_WIN32_SURFACE_EXTENSION_NAME))
    }

    create_vulkan_surface :: proc(plat_state: ^types.platform_state, vulkan_context: ^types.vulkan_context) -> bool {
        state := cast(^internal_state)(plat_state.internal_state)

        create_info: vk.Win32SurfaceCreateInfoKHR = {vk.StructureType.WIN32_SURFACE_CREATE_INFO_KHR, nil, vk.Win32SurfaceCreateFlagsKHR(nil), nil, nil}
        create_info.hinstance = state.h_instance
        create_info.hwnd = state.h_wnd

        result: vk.Result = vk.CreateWin32SurfaceKHR(vulkan_context.instance, &create_info, vulkan_context.allocator, &vulkan_context.surface)
        if result != .SUCCESS {
            console.write_error("Failed to create Vulkan Win32 surface!", 0)
            return false
        }

        state.surface = vulkan_context.surface
        return true
    }
}