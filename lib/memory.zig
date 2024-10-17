const std = @import("std");
//pub const allocator = std.heap.page_allocator;
pub const allocator = std.heap.wasm_allocator;

pub export fn proxy_on_memory_allocate(size: usize) [*]u8 {
    const memory = allocator.alloc(u8, size) catch unreachable;
    return memory.ptr;
}
