const std = @import("std");

const SyntaxTreeNode = @This();

pub const MatchFn = *const fn ([]const u8) bool;
pub const BuildFn = *const fn ([]const u8) bool;

pub fn any(_: []const u8) bool {
    return true;
}

loopback: ?usize = null,
match: []const MatchFn = &.{any},
build: ?BuildFn = null,
next: []const SyntaxTreeNode = &.{},
end: bool = false
