package engine

// Static assertions to ensure type sizes
#assert(size_of(u8) == 1, "U8 must be 1 byte")
#assert(size_of(u16) == 2, "U16 must be 2 bytes")
#assert(size_of(u32) == 4, "U32 must be 4 bytes")
#assert(size_of(u64) == 8, "U64 must be 8 bytes")
#assert(size_of(i8) == 1, "I8 must be 1 byte")
#assert(size_of(i16) == 2, "I16 must be 2 bytes")
#assert(size_of(i32) == 4, "I32 must be 4 bytes")
#assert(size_of(i64) == 8, "I64 must be 8 bytes")
#assert(size_of(f32) == 4, "F32 must be 4 bytes")
#assert(size_of(f64) == 8, "F64 must be 8 bytes")

// Platform detection - automatic based on ODIN_OS
when ODIN_OS == .Windows {
    KPLATFORM_WINDOWS :: true
    KPLATFORM_LINUX :: false
    KPLATFORM_ANDROID :: false
    KPLATFORM_UNIX :: false
    KPLATFORM_POSIX :: false
    KPLATFORM_APPLE :: false
    KPLATFORM_IOS :: false
    KPLATFORM_IOS_SIMULATOR :: false
    KPLATFORM_MACOS :: false

    // Ensure 64-bit on Windows
    when size_of(rawptr) != 8 {
        #panic("64-bit is required on Windows")
    }
} else when ODIN_OS == .Linux {
    KPLATFORM_WINDOWS :: false
    KPLATFORM_LINUX :: true
    KPLATFORM_ANDROID :: false  // Note: Android detection would need additional checks
    KPLATFORM_UNIX :: false
    KPLATFORM_POSIX :: true
    KPLATFORM_APPLE :: false
    KPLATFORM_IOS :: false
    KPLATFORM_IOS_SIMULATOR :: false
    KPLATFORM_MACOS :: false
} else when ODIN_OS == .Darwin {
    KPLATFORM_WINDOWS :: false
    KPLATFORM_LINUX :: false
    KPLATFORM_ANDROID :: false
    KPLATFORM_UNIX :: false
    KPLATFORM_POSIX :: true
    KPLATFORM_APPLE :: true
    KPLATFORM_IOS :: false
    KPLATFORM_IOS_SIMULATOR :: false
    KPLATFORM_MACOS :: true
} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
    KPLATFORM_WINDOWS :: false
    KPLATFORM_LINUX :: false
    KPLATFORM_ANDROID :: false
    KPLATFORM_UNIX :: true
    KPLATFORM_POSIX :: true
    KPLATFORM_APPLE :: false
    KPLATFORM_IOS :: false
    KPLATFORM_IOS_SIMULATOR :: false
    KPLATFORM_MACOS :: false
} else {
    #panic("Unknown platform")
}

