const std = @import("std");
const AST = @import("ast.zig");

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
pub const BuildFn = *const fn (builder: AST.Builder, [][]const u8) void;

pub fn any(_: []const u8) bool {
    return true;
}

debug: ?[:0]const u8 = null,
match: []const MatchFn = &.{},
build: ?BuildFn = null,
next: []const SyntaxTreeNode = &.{},
loopback: LoopType = .None,
lbnext: ?*const SyntaxTreeNode = null,
