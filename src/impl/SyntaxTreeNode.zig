const std = @import("std");
const log = @import("log.zig");
const fns = @import("fns.zig");
const Context = @import("Context.zig");

pub const SyntaxTreeNode = @This();

pub const MatchFnRet = MatchError!usize;
pub const MatchFn = fn ([][]const u8) MatchFnRet;
pub const BuildFn = fn (builder: *Context, [][]const u8) anyerror!void;
pub const MatchError = error{ OutOfTokens, DoesNotMatch };
const TraversalError = error{ NoLbNextNode, InvalidStackPop };

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
    errorAction: Action = .none,

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

    pub fn loopOrError(node: SyntaxTreeNode, errorAction: Action) Branch {
        return .{ .ptr = &node, .afterAction = .loop, .errorAction = errorAction };
    }

    pub fn leafAny() Branch {
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

    pub fn nextOrError(node: SyntaxTreeNode, errorAction: Action) Branch {
        return .{ .ptr = &node, .afterAction = .next, .errorAction = errorAction };
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
matchFns: []const (*const MatchFn) = &.{},
deferConsume: bool = false, //test for match, but don't consume it right away. instead, set a 'consume offset'
buildFn: ?(*const BuildFn) = null, //Called when a node is matched

pub fn match(comptime str: []const u8) SyntaxTreeNode {
    return .{ .matchFns = fns.eql(str) };
}

fn printstack(loopbackStack: std.ArrayList(StackValue)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        if (item.ptr.debug) |debug| std.debug.print("[{s}{s}{}:{}]", .{ debug.label, if (item.allowError) "!" else "", item.node_i, item.branch_i }) else std.debug.print("[?]", .{});
    }
    std.debug.print("\n", .{});
}

fn tab(stack: []const StackValue, connect: bool) void {
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

pub fn isMatch(node: SyntaxTreeNode, tokens: [][]const u8) MatchError![][]const u8 {
    if (node.matchFns.len == 0) return &.{};
    if (node.debug) |debug| {
        log.println("matching '{s}' ", .{debug.label}, .MatchingVerbose);
    }

    var result_tokens = tokens;
    var total_consumed: usize = 0;

    for (node.matchFns) |matchFn| {
        const consumed = matchFn(result_tokens) catch |err| {
            log.println(" => N", .{}, .MatchingVerbose);
            return err;
        };
        total_consumed += consumed;
        log.print("({})", .{consumed}, .MatchingVerbose);
        result_tokens = result_tokens[consumed..];
    }

    log.print("\"", .{}, .Matching);
    for (tokens[0..total_consumed]) |value| {
        log.print("{s} ", .{value}, .Matching);
    }
    log.print("\"", .{}, .Matching);

    log.print(" => Y", .{}, .MatchingVerbose);
    log.ln(.Matching);
    return tokens[0..total_consumed];
}

const StackValue = struct {
    ptr: *const SyntaxTreeNode,
    branch_i: usize = 0,
    node_i: usize = std.math.maxInt(usize),
    allowError: bool = false,
};

pub fn traverse(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
    var tokens = start_tokens;

    var stack = std.ArrayList(StackValue).initCapacity(gpa, 32) catch @panic("OOM");
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

            if (result) |matched_tokens| {
                //log.ln(.Traversal);
                if (next.ptr.buildFn) |build| try build(ctx, matched_tokens);

                if (next.ptr.deferConsume) {
                    tokenOffset += matched_tokens.len;
                    log.println("defer {}", .{tokenOffset}, .Traversal);
                } else {
                    if (matched_tokens.len > 0) {
                        tokens = tokens[tokenOffset + matched_tokens.len ..];
                        if (tokenOffset > 0) log.println("defer end", .{}, .Traversal);
                        tokenOffset = 0;
                    }
                }

                stack.items[stack.items.len - 1].node_i = i;
                if (next.ptr.branches.len > 0) {
                    tab(stack.items, true);
                    log.println("{s}", .{if (next.ptr.debug) |debug| debug.label else "┐"}, .Traversal);
                }

                stack.append(gpa, .{ .ptr = next.ptr, .allowError = next.errorAction != .none }) catch @panic("OOM");
                continue :loop;
            } else |_| continue;
            // else |err| {
            //     if (next.allowError) {
            //         _ = stack.pop();
            //         continue :loop;
            //     } else return err;
            // }
        }

        if (current.allowError) {
            // backtrack: while (true) {
            //     log.println("error", .{}, .Traversal);
            //     _ = stack.pop();
            //     const previous = stack.getLast();
            //     const action = previous.ptr.branches[previous.group_i][@intCast(previous.node_i)].errorAction;

            //     switch (action) {
            //         .end => return,
            //         .none => continue :backtrack,
            //         .loop => {
            //             stack.items[stack.items.len - 1].node_i = -1;
            //             continue :loop;
            //         },
            //         .detour => {
            //             //stack.items[stack.items.len - 1].node_i += 1;
            //             continue :loop;
            //         },
            //         .next => {
            //             stack.items[stack.items.len - 1].group_i += 1;
            //             stack.items[stack.items.len - 1].node_i = -1;
            //             continue :loop;
            //         },
            //         .prev => {
            //             stack.items[stack.items.len - 1].group_i -= 1;
            //             stack.items[stack.items.len - 1].node_i = -1;
            //             continue :loop;
            //         },
            //     }
            // }
        } else {
            ctx.printLineError(@ptrCast(tokens[0].ptr));
            return MatchError.DoesNotMatch;
        }
    }
}

// fn traverseNodes(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
//     var tokens = start_tokens;
//     var currentNode: SyntaxTreeNode = start_node;
//     var loopbackStack = std.ArrayList(SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
//     defer loopbackStack.deinit(gpa);

//     var savedTokensStack = std.ArrayList([][]const u8).initCapacity(gpa, 32) catch @panic("OOM");
//     defer savedTokensStack.deinit(gpa);

//     mainloop: while (true) {
//         ctx.progressNode.setCompletedItems(tokens.len);
//         if (currentNode.debug != null) {
//             debugPrint("current node: {s} ({any} tokens)\n", .{ currentNode.debug.?, tokens.len });
//         }

//         if (tokens.len == 0) {
//             if (currentNode.loopback == .Master or currentNode.loopback == .End) {
//                 return;
//             } else {
//                 return SyntaxTreeNode.MatchError.OutOfTokens;
//             }
//         }

//         try switch (currentNode.loopback) {
//             .After => {
//                 debugPrint("after:{?s} - ", .{currentNode.debug});
//                 var copy = currentNode;
//                 copy.next = copy.after;
//                 copy.tokens = .Current;
//                 copy.debug = .{ .label = copy.debug.?.label_after, .label_after = copy.debug.?.label_after };
//                 copy.loopback = .None;
//                 try loopbackStack.append(gpa, copy);
//                 //printstack(loopbackStack);
//             },
//             .JumpAfter => {
//                 debugPrint("jumpafter:{?s} - ", .{currentNode.debug});
//                 try loopbackStack.append(gpa, SyntaxTreeNode{
//                     .next = &.{
//                         SyntaxTreeNode{
//                             .loopback = .Jump,
//                             .build = currentNode.build_after,
//                         },
//                     },
//                 });
//                 //printstack(loopbackStack);
//             },
//             .Self => {
//                 debugPrint("self:{?s} - ", .{currentNode.debug});
//                 try loopbackStack.append(gpa, currentNode);
//                 //printstack(loopbackStack);
//             },
//             .Master => loopbackStack.append(gpa, currentNode),
//             .Jump => {
//                 const last = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;
//                 currentNode = last;

//                 if (currentNode.loopback == .After) {
//                     currentNode.next = currentNode.after;
//                 }
//                 debugPrint("jump => [{?s}] - ", .{currentNode.debug});
//                 //printstack(loopbackStack);
//                 continue :mainloop;
//             },
//             .JumpPrevious => {
//                 _ = loopbackStack.pop();
//                 currentNode = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;

//                 debugPrint("popjump => [{?s}] - ", .{currentNode.debug});
//                 //printstack(loopbackStack);
//                 continue :mainloop;
//             },
//             .Jump2Previous => {
//                 _ = loopbackStack.pop();
//                 _ = loopbackStack.pop();
//                 currentNode = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;

//                 debugPrint("popjump => [{?s}] - ", .{currentNode.debug});
//                 //printstack(loopbackStack);
//                 continue :mainloop;
//             },
//             .None => {},
//             .End => {},
//             .BranchAfter => {},
//         };

//         for (currentNode.next, 0..) |*next, i| {
//             const result_err = next.*.isMatch(tokens);

//             if (result_err) |result| {
//                 if (currentNode.loopback == .BranchAfter) {
//                     var copy = currentNode;
//                     copy.next = copy.after[i..];
//                     copy.tokens = .Current;
//                     copy.debug = null;
//                     copy.loopback = .None;
//                     try loopbackStack.append(gpa, copy);
//                     debugPrint("branch #{} => [{?s}] - ", .{ i, copy.debug });
//                     //printstack(loopbackStack);
//                 }
//                 const tok_before = tokens;
//                 tokens = tokens[result.len..];
//                 currentNode = next.*;
//                 if (currentNode.build != null) {
//                     if (currentNode.tokens == .Saved) {
//                         const toks = savedTokensStack.pop() orelse @panic("out of saved tokens");
//                         const err = currentNode.build.?(ctx, toks);
//                         err catch {
//                             ctx.printLineError(@ptrCast(tok_before[0].ptr));
//                             return err;
//                         };
//                     } else {
//                         const err = currentNode.build.?(ctx, result);
//                         err catch {
//                             ctx.printLineError(@ptrCast(tok_before[0].ptr));
//                             return err;
//                         };
//                     }
//                 }
//                 if (currentNode.tokens == .Save) {
//                     try savedTokensStack.append(gpa, result);
//                 }
//                 continue :mainloop;
//             } else |_| {
//                 debugPrint("checking next...\n", .{});
//                 continue;
//             }
//         }

//         if (currentNode.debug != null) {
//             debugPrint("no match found for node {s}. exiting\n", .{currentNode.debug.?});
//         }

//         ctx.printLineError(@ptrCast(tokens[0].ptr));

//         return SyntaxTreeNode.MatchError.DoesNotMatch;
//     }
// }
