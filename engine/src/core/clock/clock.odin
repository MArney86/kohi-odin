package clock

import types "../../types"
import platform "../platform"

update :: proc(clock: ^types.clock) {
    if clock.start_time != 0.0 {
        clock.elapsed_time = platform.get_absolute_time() - clock.start_time;
    }
}

start :: proc(clock: ^types.clock) {
    clock.start_time = platform.get_absolute_time();
    clock.elapsed_time = 0.0;
}

stop :: proc(clock: ^types.clock) {
    clock.start_time = 0.0;
}