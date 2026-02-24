const std = @import("std");

const SyntaxTreeNode = @This();

const Type = enum {
    Ambigious,
    Strict,
    SectionLabel,
    Variable,
    Type,
    StepNumber,
    Condition,
    Expression,
    Section,
    StepDecl,
    ArgsDecl,
    Argument,
    Paragraph,
    Sentence,
};

pub fn Eq(comptime eqq: []const u8) type {
    return struct {
        fn fun(str: [][]const u8) ?u8 {
            if (std.mem.eql(u8, str[0], eqq)) return 1;
            return null;
        }
    };
}

pub fn any(_: [][]const u8) ?u8 {
    return 0;
}

type: Type = .Ambigious, //sets the type of whole branch expression
match: *const fn ([][]const u8) ?u8 = any,
build: ?*const fn ([]const u8) bool = null,
next: []const SyntaxTreeNode = &.{},
