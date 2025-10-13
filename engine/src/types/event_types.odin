package types

CHAR :: u8 // 8-bit character type

event_context :: struct {
    // 128 bytes union data
    data: union {
        [2]i64,
        [2]u64,
        [2]f64,
        [4]i32,
        [4]u32,
        [4]f32,
        [8]i16,
        [8]u16,
        [16]i8,
        [16]u8,
    },
}

system_event_codes :: enum u16{
    //Shuts the application down on the next frame
    EVENT_CODE_APPLICATION_QUIT = 1,
    
    // Keyboard key pressed
    /* Context usage:
     * u16 key_code = data.data.u16[0];
     */
    EVENT_CODE_KEY_PRESSED = 2,

    // Keyboard key released
    /* Context usage:
     * u16 key_code = data.data.u16[0];
     */
    EVENT_CODE_KEY_RELEASED = 3,

    // Mouse button pressed
    /* Context usage:
     * u16 button = data.data.u16[0];
     */
    EVENT_CODE_BUTTON_PRESSED = 4,

    // Mouse button released
    /* Context usage:
     * u16 button = data.data.u16[0];
     */
    EVENT_CODE_BUTTON_RELEASED = 5,

    // Mouse moved
    /* Context usage:
     * u16 x = data.data.u16[0];
     * u16 y = data.data.u16[1];
     */
    EVENT_CODE_MOUSE_MOVED = 6,
    
    //Mouse wheel scrolled
    /* Context usage:
     * u8 z_delta = data.data.u8[0];
     */
    EVENT_CODE_MOUSE_WHEEL = 7,

    // Resized/resolution changed from the OS.
    /* Context usage:
     * u16 width = data.data.u16[0];
     * u16 height = data.data.u16[1];
     */
    EVENT_CODE_RESIZED = 8,
    
    MAX_EVENT_CODE = 255,
}