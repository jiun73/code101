const std = @import("std");
const log = @import("log.zig");
const Builder = @import("Builder.zig");

pub const OpStack = @This();

pub const Op = enum {
    Add,
    Sub,
    Mul,
    Div,
    Rem,
    Square,
    SquareRoot,
    None,
    GreaterThan,
    LessThan,
    GreaterThanOrEqualTo,
    LessThanOrEqualTo,
    EqualTo,
    Store,
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
    log.println("stack cleared", .{}, .Ops);
}

pub fn getResultSafe(self: *OpStack) Error!Builder.Value {
    return self.result orelse return Error.NoResult;
}

pub fn getResult(self: *OpStack) Error!Builder.Value {
    const result = self.result orelse return Error.NoResult;
    self.clear();
    self.clearResult();
    return result;
}

pub fn printstack(self: *OpStack) void {
    log.print("vars: ", .{}, .Ops);
    for (self.varStack.items) |vr| {
        vr.print(.Ops);
    }
    log.ln(.Ops);
    log.print("ops:  ", .{}, .Ops);
    for (self.opStack.items) |op| {
        log.print("{}", .{op}, .Ops);
    }
    log.ln(.Ops);
}

pub fn setResult(self: *OpStack, b: *Builder) (Error || Builder.Error)!void {
    if (self.varStack.items.len > 1) {
        self.printstack();
        return Error.TooManyLeftover;
    }
    if (self.varStack.items.len < 1) return Error.NoLeftover;
    self.result = try self.varStack.items[0].getValue(b);
    log.print("result set", .{}, .Ops);
}

pub fn pushVal(self: *OpStack, gpa: std.mem.Allocator, value: Builder.Value) void {
    self.varStack.append(gpa, .{ .value = value }) catch @panic("OOM");
    self.printstack();
}

pub fn pushRef(self: *OpStack, gpa: std.mem.Allocator, ref: []const u8) void {
    self.varStack.append(gpa, .{ .ref = ref }) catch @panic("OOM");
    self.printstack();
}

pub fn push(self: *OpStack, gpa: std.mem.Allocator, vr: Builder.ValueRef) void {
    self.varStack.append(gpa, vr) catch @panic("OOM");
    self.printstack();
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
        .Div => self.pushVal(gpa, try b.div(try self.getVal(), try self.getVal())),
        .Rem => self.pushVal(gpa, try b.rem(try self.getVal(), try self.getVal())),
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
        .Store => _ = try b.store(try self.getVal(), (try self.getVal()).getRef()),
    }
}

pub fn resolve(self: *OpStack, gpa: std.mem.Allocator, b: *Builder) (Error || Builder.Error)!void {
    log.println("resolving: ", .{}, .Ops);
    self.printstack();
    while (self.opStack.pop()) |op| {
        try self.doOp(gpa, b, op);
    }
}

pub fn resolveResult(self: *OpStack, gpa: std.mem.Allocator, b: *Builder) (Error || Builder.Error)!Builder.Value {
    try self.resolve(gpa, b);
    try self.setResult(b);
    return self.getResult();
}
