const std = @import("std");
const Context = @import("Context.zig");

const SyntaxTreeNode = @This();

const LoopType = enum {
    None,
    Master,
    End,
    Self,
    Next,
    Jump,
    JumpPrevious,
};

pub const MatchFn = *const fn ([]const u8) bool;
pub const BuildFn = *const fn (builder: *Context, [][]const u8) void;

debug: ?[:0]const u8 = null,
match: []const MatchFn = &.{},
build: ?BuildFn = null,
next: []const SyntaxTreeNode = &.{},
loopback: LoopType = .None,
lbnext: ?*const SyntaxTreeNode = null,

pub const MatchError = error{ OutOfTokens, DoesNotMatch };

pub fn isMatch(node: SyntaxTreeNode, tokens: [][]const u8) MatchError![][]const u8 {
    if (node.match.len == 0) return &.{};
    if (node.debug != null) {
        //std.debug.print("matching '{s}' with \n", .{node.debug.?});
    }

    for (node.match, 0..) |match, i| {
        if (i >= tokens.len) return MatchError.OutOfTokens;
        const tok = tokens[i];
        //std.debug.print("[{s}]", .{tok});
        if (!match(tok)) {
            //std.debug.print(" => X\n", .{});
            return MatchError.DoesNotMatch;
        }
    }
    //std.debug.print(" => Y\n", .{});
    return tokens[0..node.match.len];
}
