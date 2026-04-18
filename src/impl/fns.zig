const std = @import("std");
const tok = @import("tok.util.zig");

const StrMatchFn = fn (str: []const u8) bool;
const MatchFn = *const fn ([]const u8) bool;

pub fn eq(comptime eqq: []const u8) StrMatchFn {
    const T = struct {
        pub fn fun(str: []const u8) bool {
            return (std.mem.eql(u8, str, eqq));
        }
    };

    return T.fun;
}

pub fn eql(comptime fmt: []const u8) []const MatchFn {
    comptime {
        var cnt = 1;
        for (fmt) |c| {
            if (c == ' ') {
                cnt += 1;
            }
        }
        var slcs: [cnt]MatchFn = undefined;
        var off = 0;
        var id = 0;
        for (fmt, 0..) |c, i| {
            if (c == ' ') {
                slcs[id] = eq(fmt[off..i]);
                off = i + 1;
                id += 1;
            }
        }
        slcs[id] = eq(fmt[off..]);
        const ret: [cnt]MatchFn = slcs;
        return &ret;
    }
}

pub fn sectionLabel(str: []const u8) bool {
    if (str.len < 2) return false;
    if (std.mem.eql(u8, str, "principale")) return true;
    if (str[0] == '"' and str[str.len - 1] == '"') return true;
    return false;
}

pub fn stringValue(str: []const u8) bool {
    return (str[0] == '"' and str[str.len - 1] == '"');
}

pub fn variableName(str: []const u8) bool {
    return (str.len == 1) and !tok.isoneof(str[0], "0123456789");
}

pub fn integerValue(str: []const u8) bool {
    for (str) |c| {
        if (!tok.isoneof(c, "0123456789")) return false;
    }
    return true;
}
