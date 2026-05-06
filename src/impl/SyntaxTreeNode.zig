const std = @import("std");
const log = @import("log.zig");
const fns = @import("fns.zig");
const Context = @import("Context.zig");

pub const SyntaxTreeNode = @This();

pub const MatchTrue = union(enum) { match: void, consume: usize };
pub const MatchFalse = union(enum) { doesNotMatch: void, indexDoesNotMatch: usize, outOfTokens: void };
pub const Match = union(enum) { true: MatchTrue, false: MatchFalse };
pub const MatchFnRet = Match;
pub const MatchFn = fn ([][]const u8) MatchFnRet;
pub const BuildFn = fn (builder: *Context, [][]const u8) anyerror!void;
pub const MatchError = error{ OutOfTokens, DoesNotMatch };
const TraversalError = error{InvalidToken};

const DebugInfo = struct {
    label: [:0]const u8,
    label_after: [:0]const u8,

    pub fn init(comptime label: [:0]const u8) DebugInfo {
        return .{ .label = label, .label_after = "@" ++ label };
    }
};

const Action = union(enum) {
    none: void, //Return to previous node
    end: void,
    restart: void, //Restart from first branch
    loop: void, //Restart current branch
    next: void, //Go to next branch
    prev: void, //Go to previous branch
    detour: void, //Go to next node after this one
};

pub const Branch = struct {
    ptr: *const SyntaxTreeNode = &SyntaxTreeNode{},
    cancelDeferOffset: bool = false,
    afterAction: Action = .none,

    pub fn leaf(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node };
    }

    pub fn buildDetour(bld: (*const BuildFn)) Branch {
        return .{ .afterAction = .detour, .ptr = &SyntaxTreeNode{ .buildFn = bld } };
    }

    pub fn buildNext(bld: (*const BuildFn)) Branch {
        return .{ .afterAction = .next, .ptr = &SyntaxTreeNode{ .buildFn = bld } };
    }

    pub fn buildLeaf(bld: (*const BuildFn)) Branch {
        return .{ .ptr = &SyntaxTreeNode{ .buildFn = bld } };
    }

    pub fn loop(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .loop };
    }

    pub fn restart(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .restart };
    }

    pub fn exit() Branch {
        return .{};
    }

    pub fn cancelDefer() Branch {
        return .{ .cancelDeferOffset = true };
    }

    pub fn next(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .next };
    }

    pub fn detour(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .detour };
    }

    pub fn prev(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .prev };
    }

    pub fn end() Branch {
        return .{ .afterAction = .end };
    }

    pub fn initA(node: SyntaxTreeNode, after: Action) Branch {
        return .{ .ptr = &node, .afterAction = after };
    }
};

debug: ?DebugInfo = null,
branches: []const []const Branch = &.{},
matchFns: []const (*const MatchFn) = &.{}, //if matchFns.len == 0 then node is considered 'virtual'. Failure to match the first branch will result in returning to first non-virtual node in the stack
deferConsume: bool = false, //test for match, but don't consume it right away. instead, set a 'consume offset'
//catchError: bool = false, //on error, if a 'catch error' is found on the stack, set it as the current node with the next branch node
buildFn: ?(*const BuildFn) = null, //Called when a node is matched

pub fn match(comptime str: []const u8) SyntaxTreeNode {
    return .{ .matchFns = fns.eql(str) };
}

fn printstack(loopbackStack: std.ArrayList(StackRef)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        if (item.ptr.debug) |debug| std.debug.print("[{s}{s}{}:{}]", .{ debug.label, if (item.allowError) "!" else "", item.node_i, item.branch_i }) else std.debug.print("[?]", .{});
    }
    std.debug.print("\n", .{});
}

fn tab(stack: []const StackRef, connect: bool) void {
    log.removePrefix();
    if (stack.len <= 1) return;
    const arr = stack[0..(stack.len - 1)];

    for (arr, 0..) |_, i| {
        // const node = item.ptr.groups[item.group_i][@intCast(item.node_i)];
        // switch (node.afterAction) {
        //     .end => std.debug.print(".", .{}),
        //     .none => std.debug.print("|", .{}),
        //     .detour => std.debug.print(";", .{}),
        //     .loop => std.debug.print("O", .{}),
        //     .next => std.debug.print("<", .{}),
        //     .prev => std.debug.print(">", .{}),
        // }
        if (i == (arr.len - 1) and connect) {
            log.appendPrefix("├─");
        } else {
            log.appendPrefix("│ ");
        }
        //std.debug.print("|\t", .{});
    }
}

pub fn isMatch(node: SyntaxTreeNode, tokens: [][]const u8) MatchFnRet {
    //if (node.matchFns.len == 0) return .{ .true = .match };
    if (node.debug) |debug| {
        log.println("matching '{s}' ", .{debug.label}, .MatchingVerbose);
    }

    var result_tokens = tokens;
    var total_consumed: usize = 0;

    for (node.matchFns) |matchFn| {
        switch (matchFn(result_tokens)) {
            .true => |trueval| switch (trueval) {
                .consume => |consumed| {
                    total_consumed += consumed;
                    log.print("({})", .{consumed}, .MatchingVerbose);
                    result_tokens = result_tokens[consumed..];
                },
                .match => {},
            },
            .false => |falseval| {
                log.println(" => N", .{}, .MatchingVerbose);
                return .{ .false = falseval };
            },
        }
    }

    log.print("\"", .{}, .Matching);
    for (tokens[0..total_consumed]) |value| {
        log.print("{s} ", .{value}, .Matching);
    }
    log.print("\"", .{}, .Matching);

    log.print(" => Y", .{}, .MatchingVerbose);
    log.ln(.Matching);
    return .{ .true = .{ .consume = total_consumed } };
    //tokens[0..total_consumed];
}

const StackRef = struct {
    ptr: *const SyntaxTreeNode,
    has_matched: bool = false,
    branch_i: usize = 0,
    node_i: usize = std.math.maxInt(usize),
};

pub fn traverse(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
    var tokens = start_tokens;

    var stack = std.ArrayList(StackRef).initCapacity(gpa, 32) catch @panic("OOM");
    defer stack.deinit(gpa);
    stack.append(ctx.gpa, .{ .ptr = &start_node }) catch @panic("OOM");

    var tokenOffset: usize = 0;

    loop: while (true) {
        tab(stack.items, false);
        const current = stack.getLast();

        if (current.ptr.branches.len == 0) {
            var first = true;
            backtrack: while (true) {
                _ = stack.pop();
                if (!first) {
                    tab(stack.items[0..stack.items.len], true);
                    log.println("┘", .{}, .Traversal);
                } else {
                    first = false;
                }

                var previous = &stack.items[stack.items.len - 1];
                const branch = previous.ptr.branches[previous.branch_i][previous.node_i];
                const action = branch.afterAction;

                //log.println("backtrack {s} (i:{};group:{})", .{ if (previous.ptr.debug) |debug| debug.label else "?", previous.node_i, previous.group_i }, .Traversal);
                //tab(stack.items[0..(stack.items.len - 1)], false);
                tab(stack.items[0..(stack.items.len - 1)], false);

                if (branch.cancelDeferOffset) {
                    tokenOffset = 0;
                    log.println("cancelled defer", .{}, .Traversal);
                }

                switch (action) {
                    .end => return,
                    .none => {
                        //tab(stack.items[0..(stack.items.len - 1)], true);
                        //log.ln(.Traversal);
                        //log.println("┘", .{}, .Traversal);
                        continue :backtrack;
                    },
                    .restart => {
                        previous.branch_i = 0;
                        previous.node_i = std.math.maxInt(usize);
                        log.println("#", .{}, .Traversal);
                        continue :loop;
                    },
                    .detour => {
                        log.println("║", .{}, .Traversal);
                        //stack.items[stack.items.len - 1].node_i -= 1;
                        continue :loop;
                    },
                    .loop => {
                        log.println("@", .{}, .Traversal);
                        previous.node_i = std.math.maxInt(usize);
                        continue :loop;
                    },
                    .next => {
                        previous.branch_i += 1;
                        previous.node_i = std.math.maxInt(usize);
                        log.println("{}", .{stack.items[stack.items.len - 1].branch_i}, .Traversal);
                        continue :loop;
                    },
                    .prev => {
                        previous.branch_i -= 1;
                        previous.node_i = std.math.maxInt(usize);
                        log.println("{}", .{stack.items[stack.items.len - 1].branch_i}, .Traversal);
                        continue :loop;
                    },
                }
            }
        }

        const ni = (current.node_i +% 1);
        const sub = current.ptr.branches[current.branch_i][ni..];

        for (sub, ni..) |next, i| {
            //log.print("i:{} ", .{i}, .Traversal);
            const result = next.ptr.isMatch(tokens[tokenOffset..]);

            switch (result) {
                .true => |trueval| {
                    stack.items[stack.items.len - 1].has_matched = true;

                    var consumed_count: usize = 0;
                    switch (trueval) {
                        .consume => |consumed| {
                            consumed_count = consumed;
                        },
                        else => {},
                    }

                    const matched_tokens = tokens[tokenOffset..(tokenOffset + consumed_count)];

                    if (next.ptr.buildFn) |build| try build(ctx, matched_tokens);

                    if (next.ptr.deferConsume) {
                        tokenOffset += matched_tokens.len;
                        log.println("defer {}", .{tokenOffset}, .Traversal);
                    } else {
                        if (matched_tokens.len > 0) {
                            tokens = tokens[tokenOffset + consumed_count ..];
                            if (tokenOffset > 0) log.println("defer end", .{}, .Traversal);
                            tokenOffset = 0;
                        }
                    }

                    stack.items[stack.items.len - 1].node_i = i;
                    if (next.ptr.branches.len > 0) {
                        tab(stack.items, true);
                        log.println("{s}", .{if (next.ptr.debug) |debug| debug.label else "┐"}, .Traversal);
                    }

                    stack.append(gpa, .{ .ptr = next.ptr }) catch @panic("OOM");
                    continue :loop;
                },
                .false => continue,
            }
        }

        if (!current.has_matched and current.ptr.matchFns.len == 0) {
            _ = stack.pop();
            tab(stack.items, false);
            log.println("no match: virtual node, so returning", .{}, .Traversal);
            continue :loop;
        }

        ctx.printLineError(@ptrCast(tokens[0].ptr));
        return MatchError.DoesNotMatch;
    }
}
