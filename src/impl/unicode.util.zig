const std = @import("std");

pub fn stripFirstAndLast(str: []const u8) []const u8 {
    var view = std.unicode.Utf8View.init(str) catch @panic("invalid UTF8");
    var iter = view.iterator();
    const count = std.unicode.utf8CountCodepoints(str) catch @panic("invalid UTF8");

    var ret: []const u8 = str[0..0];

    var i: usize = 0;
    while (iter.nextCodepointSlice()) |codepoint| {
        if (i == 0) {
            i += 1;
            continue;
        }
        if (i == 1) {
            ret.ptr = codepoint.ptr;
            ret.len = codepoint.len;
        } else if (i == count - 1) {
            break;
        } else {
            ret.len += codepoint.len;
        }

        i += 1;
    }

    return ret;
}

pub fn strToCodepointSliceList(buff: [][]const u8, str: []const u8) !void {
    const view = try std.unicode.Utf8View.init(str);
    var iter = view.iterator();

    var i: usize = 0;
    while (iter.nextCodepointSlice()) |slice| {
        buff[i] = slice;
        i += 1;
    }
}

pub fn utf8ListComptime(str: []const u8) []const []const u8 {
    comptime {
        const cnt = std.unicode.utf8CountCodepoints(str) catch @compileError("invalid UTF8");
        var buff: [cnt][]const u8 = [_][]const u8{undefined} ** cnt;
        var view = std.unicode.Utf8View.initComptime(str);
        var iter = view.iterator();

        var i: usize = 0;
        while (iter.nextCodepointSlice()) |slice| {
            buff[i] = slice;
            i += 1;
        }

        const ret = buff;

        return &ret;
    }
}

pub fn strToCodepointSliceListAlloc(gpa: std.mem.Allocator, str: []const u8) ![]const []const u8 {
    const buff = gpa.alloc([]const u8, try std.unicode.utf8CountCodepoints(str)) catch @panic("OOM");
    try strToCodepointSliceList(buff, str);
    return buff;
}
