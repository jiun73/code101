const std = @import("std");

const buffer_size = 128;
var const_buffer: [buffer_size]u8 = [_]u8{undefined} ** buffer_size;

var add_prefix = true;
var line_prefix: []const u8 = const_buffer[0..0];

pub const LogTy = enum { Traversal, Matching, MatchingVerbose, Building, Ops, Tokenize };

const allowedLogs = [_]LogTy{ .Traversal, .Matching, .Building, .MatchingVerbose, .Tokenize };

pub fn isAllowed(comptime ty: LogTy) bool {
    for (allowedLogs) |all| {
        if (all == ty) return true;
    }
    return false;
}

pub fn print(comptime fmt: []const u8, args: anytype, comptime ty: LogTy) void {
    if (!isAllowed(ty)) return;
    if (add_prefix == true) {
        std.debug.print("{s}", .{line_prefix});
        add_prefix = false;
    }
    std.debug.print(fmt, args);
}

pub fn ln(comptime ty: LogTy) void {
    print("\n", .{}, ty);
    add_prefix = true;
}

pub fn println(comptime fmt: []const u8, args: anytype, comptime ty: LogTy) void {
    print(fmt, args, ty);
    ln(ty);
}

pub fn setPrefix(new: []const u8) void {
    @memcpy(const_buffer[0..new.len], new);
    line_prefix = const_buffer[0..new.len];
}

pub fn removePrefix() void {
    line_prefix = "";
}

pub fn appendPrefix(new: []const u8) void {
    @memcpy(const_buffer[line_prefix.len..(line_prefix.len + new.len)], new);
    line_prefix = const_buffer[0..(line_prefix.len + new.len)];
}
