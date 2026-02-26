const std = @import("std");

pub const VariableNode = struct {};

pub const FunctionNode = struct {};

pub const Node = union(enum) {
    variable: VariableNode,
    function: FunctionNode,
};

pub const Builder = struct {
    gpa: std.mem.Allocator,
};
