const std = @import("std");

pub fn isoneof(char: u8, list: []const u8) bool {
    return std.mem.indexOfScalar(u8, list, char) != null;
}
