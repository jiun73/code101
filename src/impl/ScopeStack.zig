const std = @import("std");
const log = @import("log.zig");
const Builder = @import("Builder.zig");

pub const ScopeType = union(enum) {
    global: void,
    function: []const u8,
    block: Builder.Block,
};

pub const Error = error{ StepNotDefined, VariableNotDeclared, FunctionNotDefined, NotInFunctionScope, NotInBlockScope, NoNextBlock };

const VariableValueRecord = struct { value: Builder.Value, isPointerToValue: bool = false };
const FunctionRecord = struct { body: Builder.Function, def: ?Builder.FunctionDefinition };

pub const Scope = struct {
    ty: ScopeType,
    vars: std.StringHashMap(VariableValueRecord),
    fns: std.StringHashMap(FunctionRecord),
    steps: std.StringHashMap(Builder.Block),
    nextBlock: ?Builder.Block = null,
    elseBlock: ?Builder.Block = null,

    pub fn init(gpa: std.mem.Allocator, ty: ScopeType) Scope {
        const vars = std.StringHashMap(VariableValueRecord).init(gpa);
        const fns = std.StringHashMap(FunctionRecord).init(gpa);
        const steps = std.StringHashMap(Builder.Block).init(gpa);
        return .{ .vars = vars, .fns = fns, .ty = ty, .steps = steps };
    }

    pub fn deinit(s: *Scope, gpa: std.mem.Allocator) void {
        s.vars.deinit();

        var iter = s.fns.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.def) |def| {
                def.dealloc(gpa);
            }
        }

        s.fns.deinit();
        s.steps.deinit();
    }

    pub fn setStep(s: *Scope, name: []const u8, step: Builder.Block) void {
        s.steps.put(name, step) catch @panic("PDM");
    }

    pub fn setFunction(s: *Scope, def: Builder.FunctionDefinition, body: Builder.Function) void {
        s.fns.put(def.name, .{ .body = body, .def = def }) catch @panic("PDM");
    }

    pub fn setExternalFunction(s: *Scope, name: []const u8, body: Builder.Function) void {
        s.fns.put(name, .{ .body = body, .def = null }) catch @panic("PDM");
    }

    pub fn setVariableValue(s: *Scope, name: []const u8, value: Builder.Value) void {
        s.vars.put(name, .{ .value = value }) catch @panic("PDM");
    }

    pub fn setVariableValuePtr(s: *Scope, name: []const u8, value: Builder.Value) void {
        s.vars.put(name, .{ .value = value, .isPointerToValue = true }) catch @panic("PDM");
    }

    pub fn getStep(s: *Scope, name: []const u8) ?Builder.Block {
        return s.steps.get(name);
    }

    pub fn getFunction(s: *Scope, name: []const u8) ?FunctionRecord {
        return s.fns.get(name);
    }

    pub fn getVariableValue(s: *Scope, name: []const u8) ?VariableValueRecord {
        return s.vars.get(name);
    }
};

pub const ScopeStack = @This();

scopes: std.ArrayList(Scope),

pub fn init(gpa: std.mem.Allocator) ScopeStack {
    var scopes = std.ArrayList(Scope).initCapacity(gpa, 4) catch @panic("PDM");
    scopes.append(gpa, .init(gpa, .global)) catch @panic("PDM"); //Global Scope

    return .{ .scopes = scopes };
}
pub fn deinit(st: *ScopeStack, gpa: std.mem.Allocator) void {
    for (st.scopes.items) |*scope| {
        scope.deinit(gpa);
    }

    st.scopes.deinit(gpa);
}

pub fn enterScope(st: *ScopeStack, gpa: std.mem.Allocator, s: Scope) void {
    log.println("entering scope: {}", .{s.ty}, .Building);
    st.scopes.append(gpa, s) catch @panic("PDM");
}
pub fn exitScope(st: *ScopeStack, gpa: std.mem.Allocator) void {
    if (st.scopes.items.len <= 1) @panic("Erreur interne: tentative de partir de la Scope Global");
    var scope = st.scopes.pop() orelse unreachable;
    log.println("exiting scope: {}", .{scope.ty}, .Building);
    scope.deinit(gpa);
}

pub fn getGlobalScope(st: ScopeStack) *Scope {
    return &st.scopes.items[0];
}

pub fn getCurrentScope(st: ScopeStack) *Scope {
    return &st.scopes.items[st.scopes.items.len - 1];
}

pub fn getNextBlock(st: ScopeStack) Error!Builder.Block {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = st.scopes.items[i];
        if (scope.nextBlock) |nb| return nb;
    }
    return Error.NoNextBlock;
    //@panic("Erreur Interne: pas de Scope Function trouvé comme parent");
}

pub fn getParentBlock(st: ScopeStack) Error!Builder.Block {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = st.scopes.items[i];
        switch (scope.ty) {
            .block => |block| return block,
            else => continue,
        }
    }
    return Error.NotInBlockScope;
    //@panic("Erreur Interne: pas de Scope Function trouvé comme parent");
}

pub fn getParentFunctionScopeName(st: ScopeStack) Error![]const u8 {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = st.scopes.items[i];
        switch (scope.ty) {
            .function => |fun| return fun,
            else => continue,
        }
    }
    return Error.NotInFunctionScope;
    //@panic("Erreur Interne: pas de Scope Function trouvé comme parent");
}

pub fn getVariableRecord(st: *ScopeStack, name: []const u8) Error!VariableValueRecord {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = &st.scopes.items[i];
        return scope.getVariableValue(name) orelse continue;
    }
    return Error.VariableNotDeclared;
}

pub fn getFunctionRecord(st: *ScopeStack, name: []const u8) Error!FunctionRecord {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = &st.scopes.items[i];
        return scope.getFunction(name) orelse continue;
    }
    log.println("Could not find function definition: {s}", .{name}, .Building);
    return Error.FunctionNotDefined;
}

pub fn getParentFunctionRecord(st: *ScopeStack) Error!FunctionRecord {
    const fn_name = try st.getParentFunctionScopeName();
    return try st.getFunctionRecord(fn_name);
}

pub fn getStepRecord(st: *ScopeStack, name: []const u8) Error!Builder.Block {
    var i = st.scopes.items.len;
    while (i > 0) {
        i -= 1;
        const scope = &st.scopes.items[i];
        return scope.getStep(name) orelse continue;
    }
    log.println("Could not find step definition: {s}", .{name}, .Building);
    return Error.StepNotDefined;
}
