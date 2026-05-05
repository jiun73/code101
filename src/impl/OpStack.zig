const std = @import("std");
const log = @import("log.zig");
const Builder = @import("Builder.zig");

pub const OpStack = @This();

pub const Data = union(enum) {
    label: []const u8,
    double: Builder.Value,
    bool: Builder.Value,
    reference: Builder.Ref,
    function: struct {},
    type: Builder.DataType,

    pub fn asRef(data: Data) !Builder.Ref {
        switch (data) {
            .reference => |ref| return ref,
            else => return Error.InvalidDataType,
        }
    }

    pub fn asDouble(data: Data, builder: *Builder) !Builder.Value {
        switch (data) {
            .double => |v| return v,
            .reference => |ref| return try builder.getVar(ref),
            else => return Error.InvalidDataType,
        }
    }

    pub fn asLabel(data: Data) ![]const u8 {
        switch (data) {
            .label => |v| return v,
            else => return Error.InvalidDataType,
        }
    }

    pub fn asValue(data: Data, builder: *Builder) !Builder.Value {
        switch (data) {
            .bool => |v| return v,
            .double => |v| return v,
            .reference => |ref| return try builder.getVar(ref),
            else => return Error.InvalidDataType,
        }
    }

    //            .ref => |ref| log.print("[{s}]", .{ref}, logty),         .value => |val| log.print("[{x}]", .{@intFromPtr(val.ref)}, logty),

    pub fn print(data: Data, comptime logty: log.LogTy) void {
        switch (data) {
            .bool => |v| return log.print("[{x}]", .{@intFromPtr(v.ref)}, logty),
            .double => |v| return log.print("[{x}]", .{@intFromPtr(v.ref)}, logty),
            .reference => |ref| return log.print("[{s}]", .{ref}, logty),
            else => return log.print("[?]", .{}, logty),
        }
    }
};

pub const Op = union(enum) {
    control: enum { Stop },
    arithmetic: union(enum) {
        unary: enum {
            Square,
            SquareRoot,
        },
        binary: enum {
            Add,
            Substract,
            Multiply,
            Divide,
            Remainder,
        },
    },
    comparison: enum {
        GreaterThan,
        LessThan,
        GreaterThanOrEqualTo,
        LessThanOrEqualTo,
        EqualTo,
        NotEqualTo,
    },
    memory: enum {
        Declare,
        Store,
    },
    call: enum {
        StartCall,
        SetArgument,
    },
    functionDefinition: enum {
        StartFunctionDef,
        PushArgumentDef,
        SetResultType,
    },
};

dataStack: std.ArrayList(Data),
opStack: std.ArrayList(Op),

pub const Error = error{
    NoResult,
    NoLeftover,
    TooManyLeftover,
    OutOfValues,
    InvalidDataType,
};

pub fn init(gpa: std.mem.Allocator) OpStack {
    const varStack = std.ArrayList(Data).initCapacity(gpa, 32) catch @panic("OOM");
    const opStack = std.ArrayList(Op).initCapacity(gpa, 32) catch @panic("OOM");

    return .{
        .opStack = opStack,
        .dataStack = varStack,
    };
}

pub fn deinit(ops: *OpStack, gpa: std.mem.Allocator) void {
    ops.opStack.deinit(gpa);
    ops.dataStack.deinit(gpa);
}

pub fn popResult(self: *OpStack) Error!Data {
    if (self.dataStack.items.len > 1) {
        self.printstack();
        return Error.TooManyLeftover;
    }
    if (self.dataStack.items.len < 1) return Error.NoLeftover;
    return self.dataStack.items[0];
}

pub fn printstack(self: *OpStack) void {
    log.print("vars: ", .{}, .Ops);
    for (self.dataStack.items) |i| {
        i.print(.Ops);
    }
    log.ln(.Ops);
    log.print("ops:  ", .{}, .Ops);
    for (self.opStack.items) |op| {
        log.print("{}", .{op}, .Ops);
    }
    log.ln(.Ops);
}

pub fn pushData(self: *OpStack, gpa: std.mem.Allocator, data: Data) void {
    self.dataStack.append(gpa, data) catch @panic("OOM");
    self.printstack();
}

pub fn pop(self: *OpStack) !Data {
    return self.dataStack.pop() orelse return Error.OutOfValues;
}

pub fn popLabel(self: *OpStack) ![]const u8 {
    return (try self.pop()).asLabel();
}

pub fn popRef(self: *OpStack) ![]const u8 {
    return (try self.pop()).asRef();
}

pub fn popValue(self: *OpStack, b: *Builder) !Builder.Value {
    return (try self.pop()).asValue(b);
}

pub fn popDouble(self: *OpStack, b: *Builder) !Builder.Value {
    return (try self.pop()).asDouble(b);
}

pub fn getLast(self: *OpStack) Builder.ValueRef {
    return self.dataStack.items[self.dataStack.items.len - 1];
}

pub fn pushOp(self: *OpStack, gpa: std.mem.Allocator, op: Op) void {
    self.opStack.append(gpa, op) catch @panic("OOM");
}

pub fn doOpSwitch(self: *OpStack, gpa: std.mem.Allocator, builder: *Builder, op: Op) !?Data {
    switch (op) {
        .arithmetic => |ar_op| switch (ar_op) {
            .unary => |un_op| {
                const value = try self.popDouble(builder);

                const result = switch (un_op) {
                    .Square => builder.square(value),
                    .SquareRoot => builder.squareRoot(value),
                };

                return .{ .double = result };
            },
            .binary => |bin_op| {
                const RHS = try self.popDouble(builder);
                const LHS = try self.popDouble(builder);

                const result = switch (bin_op) {
                    .Multiply => builder.mul(LHS, RHS),
                    .Divide => builder.div(LHS, RHS),
                    .Remainder => builder.rem(LHS, RHS),
                    .Add => builder.add(LHS, RHS),
                    .Substract => builder.sub(LHS, RHS),
                };

                return .{ .double = result };
            },
        },
        .comparison => |c_op| {
            const RHS = try self.popDouble(builder);
            const LHS = try self.popDouble(builder);

            const result = switch (c_op) {
                .EqualTo => builder.eq(LHS, RHS),
                .NotEqualTo => builder.neq(LHS, RHS),
                .GreaterThan => builder.gt(LHS, RHS),
                .GreaterThanOrEqualTo => builder.gte(LHS, RHS),
                .LessThan => builder.lt(LHS, RHS),
                .LessThanOrEqualTo => builder.lte(LHS, RHS),
            };

            return .{ .bool = result };
        },
        .call => |c_op| switch (c_op) {
            .StartCall => {},
            .SetArgument => {},
        },
        .memory => |mem_op| switch (mem_op) {
            .Declare => {
                const lbl = try self.popLabel();
                _ = builder.declare(gpa, lbl);
            },
            .Store => {
                const RHS = try self.popDouble(builder);
                const LHS = try self.popRef();

                _ = try builder.store(LHS, RHS);
            },
        },
        .functionDefinition => |fn_op| switch (fn_op) {
            .StartFunctionDef => {},
            .PushArgumentDef => {},
            .SetResultType => {},
        },
        .control => unreachable,
    }
    return null;
}

pub fn doOp(self: *OpStack, gpa: std.mem.Allocator, builder: *Builder, op: Op) !void {
    const result = (try self.doOpSwitch(gpa, builder, op)) orelse return;
    self.pushData(gpa, result);
}

pub fn resolve(self: *OpStack, gpa: std.mem.Allocator, builder: *Builder) (Error || Builder.Error)!void {
    while (self.opStack.pop()) |op| {
        switch (op) {
            .control => |c_op| switch (c_op) {
                .Stop => {
                    log.println("resolved: ", .{}, .Ops);
                    self.printstack();
                    return;
                },
            },
            else => {},
        }

        try self.doOp(gpa, builder, op);
    }

    log.println("resolved: ", .{}, .Ops);
    self.printstack();
}

pub fn resolveResult(self: *OpStack, gpa: std.mem.Allocator, b: *Builder) (Error || Builder.Error)!Builder.Value {
    try self.resolve(gpa, b);
    try self.setResult(b);
    return self.popResult();
}
