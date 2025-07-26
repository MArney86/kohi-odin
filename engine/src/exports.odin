package Engine

import Kdefines "./defines"
import Kcore "./core"
import Kasserts "./asserts" 
import "base:runtime"

// KAPI equivalent for different build configurations
when Kcore.KEXPORT {
    // When exporting (building as DLL/shared library)
    when ODIN_OS == .Windows {
        // On Windows, use @(export) attribute for DLL exports
        KAPI :: proc(fn: typeid) -> typeid {
            return fn
        }
    } else {
        // On Unix-like systems, symbols are visible by default
        KAPI :: proc(fn: typeid) -> typeid {
            return fn
        }
    }
} else {
    // When importing (using the DLL/shared library)
    when ODIN_OS == .Windows {
        // On Windows, procedures will be imported via foreign blocks
        KAPI :: proc(fn: typeid) -> typeid {
            return fn
        }
    } else {
        // On Unix-like systems, no special handling needed
        KAPI :: proc(fn: typeid) -> typeid {
            return fn
        }
    }
}

// Usage pattern for exported procedures:
// @(export) when KEXPORT else @(link_name="function_name")
// procedure_name :: proc "c" (params) -> return_type {
//     // implementation
// }

// Alternative simpler approach - just use export attribute directly:
// when KEXPORT {
//     @(export)
//     your_function :: proc "c" (params) -> return_type { /* body */ }
// }

when Kdefines.KEXPORT {
// KAPI exports for assertions - call internal functions with recreated location
    
    @(export, link_name="KASSERT")
    KAPI_KASSERT :: proc "c" (expr: cstring, file: cstring, line: i32) {
        // Convert C types to Odin types and call internal function with recreated location
        context = runtime.default_context()
        loc := runtime.Source_Code_Location{
            file_path = string(file),
            line = int(line),
            column = 0,
            procedure = "",
        }
        Kasserts.KASSERT(string(expr), loc)
    }
    
    @(export, link_name="KASSERT_MSG")
    KAPI_KASSERT_MSG :: proc "c" (expr: cstring, message: cstring, file: cstring, line: i32) {
        // Convert C types to Odin types and call internal function with recreated location
        context = runtime.default_context()
        loc := runtime.Source_Code_Location{
            file_path = string(file),
            line = int(line),
            column = 0,
            procedure = "",
        }
        Kasserts.KASSERT_MSG(string(expr), string(message), loc)
    }
    
    @(export, link_name="KASSERT_DEBUG")
    KAPI_KASSERT_DEBUG :: proc "c" (expr: cstring, file: cstring, line: i32) {
        // Convert C types to Odin types and call internal function with recreated location
        context = runtime.default_context()
        loc := runtime.Source_Code_Location{
            file_path = string(file),
            line = int(line),
            column = 0,
            procedure = "",
        }
        Kasserts.KASSERT_DEBUG(string(expr), loc)
    }

// KAPI exports for logging - call internal functions and recreate/cast types

    @(export, link_name="log_output")
    KAPI_log_output :: proc "c" (level: i32, message: cstring) {
        context = runtime.default_context()
        Kcore.log_output(log_level(level), string(message))
    }

    @(export, link_name="KFATAL")
    KAPI_KFATAL :: proc "c" (message: cstring) {
        Kcore.KFATAL(string(message))
    }

    @(export, link_name="KERROR")
    KAPI_KERROR :: proc "c" (message: cstring) {
        Kcore.KERROR(string(message))
    }

    @(export, link_name="KWARN")
    KAPI_KWARN :: proc "c" (message: cstring) {
        Kcore.KWARN(string(message))
    }

    @(export, link_name="KINFO")
    KAPI_KINFO :: proc "c" (message: cstring) {
        Kcore.KINFO(string(message))
    }

    @(export, link_name="KDEBUG")
    KAPI_KDEBUG :: proc "c" (message: cstring) {
        Kcore.KDEBUG(string(message))
    }
    
    @(export, link_name="KTRACE")
    KAPI_KTRACE :: proc "c" (message: cstring) {
        Kcore.KTRACE(string(message))
    }
}