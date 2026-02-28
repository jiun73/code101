const std = @import("std");
const tok = @import("Tokenizer.zig");

pub fn Eq(comptime eqq: []const u8) type {
    return struct {
        pub fn fun(str: []const u8) bool {
            return (std.mem.eql(u8, str, eqq));
        }
    };
}

pub fn sectionLabel(str: []const u8) bool {
    if (str.len < 2) return false;
    if (std.mem.eql(u8, str, "principale")) return true;
    if (str[0] == '"' and str[str.len - 1] == '"') return true;
    return false;
}

pub fn string(str: []const u8) bool {
    return (str[0] == '"' and str[str.len - 1] == '"');
}

pub fn variable(str: []const u8) bool {
    return (str.len == 1);
}

pub fn integer(str: []const u8) bool {
    for (str) |c| {
        if (!tok.isoneof(c, "0123456789")) return false;
    }
    return true;
}
