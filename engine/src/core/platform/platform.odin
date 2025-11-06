package platform

import time "core:time"

sleep :: proc(ms: u64) {
    time.sleep(time.Duration(ms * cast(u64)time.Millisecond))
}
