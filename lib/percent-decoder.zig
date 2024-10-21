const std = @import("std");

pub const DecodeOptions = struct {
    decode_plus_as_space: bool = true,
};

pub fn decode_alloc(allocator: std.mem.Allocator, encoded: []const u8, comptime options: DecodeOptions) ![]const u8 {
    if (encoded.len == 0) return try allocator.dupe(u8, encoded);

    var iter = decode(encoded, options);
    const first = iter.next().?;
    if (first.len == encoded.len and first.ptr == encoded.ptr) return try allocator.dupe(u8, encoded);

    var len = first.len;
    while (iter.next()) |part| len += part.len;

    var result = std.ArrayListUnmanaged(u8).initBuffer(try allocator.alloc(u8, len));

    iter = decode(encoded, options);
    while (iter.next()) |part| {
        result.appendSliceAssumeCapacity(part);
    }

    return result.items;
}

pub fn decode_maybe_append(list: *std.ArrayList(u8), encoded: []const u8, comptime options: DecodeOptions) ![]const u8 {
    // `encoded` must not reference the list's backing buffer, since it might be reallocated in this function.
    std.debug.assert(@intFromPtr(encoded.ptr) >= @intFromPtr(list.items.ptr + list.capacity) or @intFromPtr(list.items.ptr) >= @intFromPtr(encoded.ptr + encoded.len));

    if (encoded.len == 0) return encoded;

    var iter = decode(encoded, options);
    const first = iter.next().?;
    if (first.len == encoded.len and first.ptr == encoded.ptr) return first;

    const prefix_length = list.items.len;
    try list.appendSlice(first);
    while (iter.next()) |part| {
        try list.appendSlice(part);
    }

    return list.items[prefix_length..];
}

pub fn decode_append(list: *std.ArrayList(u8), encoded: []const u8, comptime options: DecodeOptions) !void {
    var iter = decode(encoded, options);
    while (iter.next()) |part| {
        try list.appendSlice(part);
    }
}

pub fn decode_in_place(encoded: []u8, comptime options: DecodeOptions) []const u8 {
    return decode_backwards(encoded, encoded, options);
}

pub fn decode_backwards(output: []u8, encoded: []const u8, comptime options: DecodeOptions) []const u8 {
    var remaining = output;
    var iter = decode(encoded, options);
    while (iter.next()) |span| {
        std.mem.copyForwards(u8, remaining, span);
        remaining = remaining[span.len..];
    }
    return output[0 .. output.len - remaining.len];
}

pub fn decode_writer(writer: anytype, encoded: []const u8, comptime options: DecodeOptions) @TypeOf(writer).Error!void {
    var iter = decode(encoded, options);
    while (iter.next()) |part| {
        try writer.writeAll(part);
    }
}

pub fn decode(encoded: []const u8, comptime options: DecodeOptions) Decoder(options) {
    return .{ .remaining = encoded };
}
pub fn Decoder(comptime options: DecodeOptions) type {
    return struct {
        remaining: []const u8,
        temp: [1]u8 = undefined,

        pub fn next(self: *@This()) ?[]const u8 {
            const remaining = self.remaining;
            if (remaining.len == 0) return null;

            if (remaining[0] == '%') {
                if (remaining.len >= 3) {
                    self.temp[0] = std.fmt.parseInt(u8, remaining[1..3], 16) catch {
                        self.remaining = remaining[1..];
                        return remaining[0..1];
                    };
                    self.remaining = remaining[3..];
                    return &self.temp;
                } else {
                    self.remaining = remaining[1..];
                    return remaining[0..1];
                }
            } else if (options.decode_plus_as_space and remaining[0] == '+') {
                self.temp[0] = ' ';
                self.remaining = remaining[1..];
                return &self.temp;
            }

            if (options.decode_plus_as_space) {
                if (std.mem.indexOfAny(u8, remaining, "%+")) |end| {
                    self.remaining = remaining[end..];
                    return remaining[0..end];
                }
            } else {
                if (std.mem.indexOfScalar(u8, remaining, '%')) |end| {
                    self.remaining = remaining[end..];
                    return remaining[0..end];
                }
            }

            self.remaining = "";
            return remaining;
        }
    };
}