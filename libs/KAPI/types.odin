package Kohi_API

//Platform types
platform_state :: struct {
    internal_state: rawptr,
}

//Game engine API types
application_config :: struct {
    start_pos_x: i16,
    start_pos_y: i16,
    width: i16,
    height: i16,
    name: string,
}

game_initialize_func :: proc(^game) -> bool
game_update_func :: proc(^game, f32) -> bool
game_render_func :: proc(^game, f32) -> bool
game_resize_func :: proc(^game, u32, u32)

game :: struct {
    app_config: application_config,
    initialize: game_initialize_func,
    update:     game_update_func,
    render:     game_render_func,
    on_resize:  game_resize_func,
    state:      rawptr,
} 

// Memory tags for allocation tracking
memory_tag :: enum {
    MEMORY_TAG_UNKNOWN, // Temporary use. Should be assigned one of the tags below or new one added.
    MEMORY_TAG_ARRAY,
    MEMORY_TAG_DARRAY,
    MEMORY_TAG_DARRAY_USED,
    MEMORY_TAG_DICT,
    MEMORY_TAG_RING_QUEUE,
    MEMORY_TAG_BST,
    MEMORY_TAG_STRING,
    MEMORY_TAG_APPLICATION,
    MEMORY_TAG_JOB,
    MEMORY_TAG_TEXTURE,
    MEMORY_TAG_MATERIAL_INSTANCE,
    MEMORY_TAG_RENDERER,
    MEMORY_TAG_GAME,
    MEMORY_TAG_TRANSFORM,
    MEMORY_TAG_ENTITY,
    MEMORY_TAG_ENTITY_NODE,
    MEMORY_TAG_SCENE,

    MEMORY_TAG_MAX_TAGS,
}

//Event types and definitions
PFN_on_event :: ^proc(code: u16, sender: rawptr, listener_inst: rawptr, data: event_context) -> bool

event_context :: struct {
    // 128 bytes union data
    data: struct #raw_union{
        I64: [2]i64,
        U64: [2]u64,
        F64: [2]f64,
        I32: [4]i32,
        U32: [4]u32,
        F32: [4]f32,
        I16: [8]i16,
        U16: [8]u16,
        I8: [16]i8,
        U8: [16]u8,
        B8: [16]b8,
        CHAR: [16]u8
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

//Input enums
buttons :: enum {
    BUTTON_LEFT,
    BUTTON_RIGHT,
    BUTTON_MIDDLE,
    BUTTON_MAX_BUTTONS,
}

keys :: enum {
    KEY_UNKNOWN = 0x00,
    KEY_BACKSPACE = 0x08,
    KEY_ENTER = 0x0D,
    KEY_TAB = 0x09,
    KEY_SHIFT = 0x10,
    KEY_CONTROL = 0x11,
    KEY_PAUSE = 0x13,
    KEY_CAPITAL = 0x14,
    KEY_ESCAPE = 0x1B,
    KEY_CONVERT = 0x1C,
    KEY_NONCONVERT = 0x1D,
    KEY_ACCEPT = 0x1E,
    KEY_MODECHANGE = 0x1F,
    KEY_SPACE = 0x20,
    KEY_PRIOR = 0x21,
    KEY_NEXT = 0x22,
    KEY_END = 0x23,
    KEY_HOME = 0x24,
    KEY_LEFT = 0x25,
    KEY_UP = 0x26,
    KEY_RIGHT = 0x27,
    KEY_DOWN = 0x28,
    KEY_SELECT = 0x29,
    KEY_PRINT = 0x2A,
    KEY_EXECUTE = 0x2B,
    KEY_SNAPSHOT = 0x2C,
    KEY_INSERT = 0x2D,
    KEY_DELETE = 0x2E,
    KEY_HELP = 0x2F,
    KEY_A = 0x41,
    KEY_B = 0x42,
    KEY_C = 0x43,
    KEY_D = 0x44,
    KEY_E = 0x45,
    KEY_F = 0x46,
    KEY_G = 0x47,
    KEY_H = 0x48,
    KEY_I = 0x49,
    KEY_J = 0x4A,
    KEY_K = 0x4B,
    KEY_L = 0x4C,
    KEY_M = 0x4D,
    KEY_N = 0x4E,
    KEY_O = 0x4F,
    KEY_P = 0x50,
    KEY_Q = 0x51,
    KEY_R = 0x52,
    KEY_S = 0x53,
    KEY_T = 0x54,
    KEY_U = 0x55,
    KEY_V = 0x56,
    KEY_W = 0x57,
    KEY_X = 0x58,
    KEY_Y = 0x59,
    KEY_Z = 0x5A,
    KEY_LWIN = 0x5B,
    KEY_RWIN = 0x5C,
    KEY_APPS = 0x5D,
    KEY_SLEEP = 0x5F,
    KEY_NUMPAD0 = 0x60,
    KEY_NUMPAD1 = 0x61,
    KEY_NUMPAD2 = 0x62,
    KEY_NUMPAD3 = 0x63,
    KEY_NUMPAD4 = 0x64,
    KEY_NUMPAD5 = 0x65,
    KEY_NUMPAD6 = 0x66,
    KEY_NUMPAD7 = 0x67,
    KEY_NUMPAD8 = 0x68,
    KEY_NUMPAD9 = 0x69,
    KEY_MULTIPLY = 0x6A,
    KEY_ADD = 0x6B,
    KEY_SEPARATOR = 0x6C,
    KEY_SUBTRACT = 0x6D,
    KEY_DECIMAL = 0x6E,
    KEY_DIVIDE = 0x6F,
    KEY_F1 = 0x70,
    KEY_F2 = 0x71,
    KEY_F3 = 0x72,
    KEY_F4 = 0x73,
    KEY_F5 = 0x74,
    KEY_F6 = 0x75,
    KEY_F7 = 0x76,
    KEY_F8 = 0x77,
    KEY_F9 = 0x78,
    KEY_F10 = 0x79,
    KEY_F11 = 0x7A,
    KEY_F12 = 0x7B,
    KEY_F13 = 0x7C,
    KEY_F14 = 0x7D,
    KEY_F15 = 0x7E,
    KEY_F16 = 0x7F,
    KEY_F17 = 0x80,
    KEY_F18 = 0x81,
    KEY_F19 = 0x82,
    KEY_F20 = 0x83,
    KEY_F21 = 0x84,
    KEY_F22 = 0x85,
    KEY_F23 = 0x86,
    KEY_F24 = 0x87,
    KEY_NUMLOCK = 0x90,
    KEY_SCROLL = 0x91,
    KEY_NUMPAD_EQUAL = 0x92,
    KEY_LSHIFT = 0xA0,
    KEY_RSHIFT = 0xA1,
    KEY_LCONTROL = 0xA2,
    KEY_RCONTROL = 0xA3,
    KEY_LMENU = 0xA4,
    KEY_RMENU = 0xA5,
    KEY_SEMICOLON = 0xBA,
    KEY_PLUS = 0xBB,
    KEY_COMMA = 0xBC,
    KEY_MINUS = 0xBD,
    KEY_PERIOD = 0xBE,
    KEY_SLASH = 0xBF,
    KEY_GRAVE = 0xC0,
    KEYS_MAX_KEYS,
}