const std = @import("std");
const Builder = @import("Builder.zig");

pub const OpStack = @This();

pub const Op = enum {
    Add,
    Sub,
    Mul,
    Square,
    SquareRoot,
    None,
    GreaterThan,
    LessThan,
    GreaterThanOrEqualTo,
    LessThanOrEqualTo,
    EqualTo,
};

varStack: std.ArrayList(Builder.ValueRef),
opStack: std.ArrayList(Op),
result: ?Builder.Value,

pub const Error = error{
    NoResult,
    NoLeftover,
    TooManyLeftover,
    OutOfValues,
};

pub fn init(gpa: std.mem.Allocator) OpStack {
    const varStack = std.ArrayList(Builder.ValueRef).initCapacity(gpa, 32) catch @panic("OOM");
    const opStack = std.ArrayList(Op).initCapacity(gpa, 32) catch @panic("OOM");

    return .{
        .opStack = opStack,
        .varStack = varStack,
        .result = null,
    };
}

pub fn deinit(ops: *OpStack, gpa: std.mem.Allocator) void {
    ops.opStack.deinit(gpa);
    ops.varStack.deinit(gpa);
}

pub fn clearResult(self: *OpStack) void {
    self.result = null;
}

pub fn clear(self: *OpStack) void {
    self.varStack.clearRetainingCapacity();
    std.debug.print("stack cleared\n", .{});
}

pub fn getResultSafe(self: *OpStack) Error!Builder.Value {
    if (self.result == null) return Error.NoResult;
    return self.result.?;
}

pub fn getResult(self: *OpStack) Error!Builder.Value {
    if (self.result == null) return Error.NoResult;
    const result = self.result;
    self.clear();
    self.clearResult();
    return result.?;
}

pub fn setResult(self: *OpStack, b: *Builder) (Error || Builder.Error)!void {
    if (self.varStack.items.len > 1) {
        std.debug.print("stack: {any}\n", .{self.varStack.items});
        return Error.TooManyLeftover;
    }
    if (self.varStack.items.len < 1) return Error.NoLeftover;
    std.debug.print("result set\n", .{});
    self.result = try self.varStack.items[0].getValue(b);
}

pub fn pushVal(self: *OpStack, gpa: std.mem.Allocator, value: Builder.Value) void {
    self.varStack.append(gpa, .{ .value = value }) catch @panic("OOM");
    std.debug.print("stack: {any}\n", .{self.varStack.items});
}

pub fn pushRef(self: *OpStack, gpa: std.mem.Allocator, ref: []const u8) void {
    self.varStack.append(gpa, .{ .ref = ref }) catch @panic("OOM");
    std.debug.print("stack: {any}\n", .{self.varStack.items});
}

pub fn push(self: *OpStack, gpa: std.mem.Allocator, vr: Builder.ValueRef) void {
    self.varStack.append(gpa, vr) catch @panic("OOM");
    std.debug.print("stack: {any}\n", .{self.varStack.items});
}

pub fn getVal(self: *OpStack) Error!Builder.ValueRef {
    return self.varStack.pop() orelse return Error.OutOfValues;
}

pub fn getLast(self: *OpStack) Builder.ValueRef {
    return self.varStack.items[self.varStack.items.len - 1];
}

pub fn pushOp(self: *OpStack, gpa: std.mem.Allocator, op: Op) void {
    self.opStack.append(gpa, op) catch @panic("OOM");
}

pub fn doOp(self: *OpStack, gpa: std.mem.Allocator, b: *Builder, op: Op) (Error || Builder.Error)!void {
    switch (op) {
        .Mul => self.pushVal(gpa, try b.mul(try self.getVal(), try self.getVal())),
        .Add => self.pushVal(gpa, try b.add(try self.getVal(), try self.getVal())),
        .Sub => self.pushVal(gpa, try b.sub(try self.getVal(), try self.getVal())),
        .Square => self.pushVal(gpa, try b.square(try self.getVal())),
        .SquareRoot => self.pushVal(gpa, try b.squareRoot(try self.getVal())),
        .EqualTo => {},
        .GreaterThan => {},
        .GreaterThanOrEqualTo => {},
        .LessThan => {},
        .LessThanOrEqualTo => {},
        .None => {},
    }
}

pub fn resolve(self: *OpStack, gpa: std.mem.Allocator, b: *Builder) (Error || Builder.Error)!void {
    std.debug.print("resolving: stack: {any}\n", .{self.varStack.items});
    while (self.opStack.pop()) |op| {
        try self.doOp(gpa, b, op);
    }
}

pub fn resolveResult(self: *OpStack, gpa: std.mem.Allocator, b: *Builder) (Error || Builder.Error)!Builder.Value {
    try self.resolve(gpa, b);
    try self.setResult(b);
    return self.getResult();
}
