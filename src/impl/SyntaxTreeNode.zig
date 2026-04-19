const std = @import("std");
const Context = @import("Context.zig");

pub const SyntaxTreeNode = @This();

const LoopType = enum {
    None,
    Master,
    End,
    Self,
    After,
    BranchAfter, //jump to one of after's nodes depending on the index of the matched next
    Jump,
    JumpAfter,
    JumpPrevious,
    Jump2Previous,
};

const TokenUsageType = enum { Current, Save, Saved };
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

const After = union(enum) {
    inherit: void,
    none: void, //Return to previous node
    end: void,
    loop: void, //re-eval node groups
    next: void, //Return and increment next_i
    prev: void, //Return and decrement next_i
};

pub const Node = struct {
    ptr: *const SyntaxTreeNode = &SyntaxTreeNode{},
    after: After = .inherit,
    allowError: bool = false,

    pub fn init(node: SyntaxTreeNode) Node {
        return .{ .ptr = &node };
    }

    pub fn buildNext(bld: (*const BuildFn)) Node {
        return .{ .after = .next, .ptr = &SyntaxTreeNode{ .build = bld } };
    }

    pub fn build(bld: (*const BuildFn)) Node {
        return .{ .ptr = &SyntaxTreeNode{ .build = bld } };
    }

    pub fn loop(node: SyntaxTreeNode) Node {
        return .{ .ptr = &node, .after = .loop };
    }

    pub fn any() Node {
        return .{};
    }

    pub fn next(node: SyntaxTreeNode) Node {
        return .{ .ptr = &node, .after = .next };
    }

    pub fn prev(node: SyntaxTreeNode) Node {
        return .{ .ptr = &node, .after = .prev };
    }

    pub fn end() Node {
        return .{ .after = .end };
    }

    pub fn initA(node: SyntaxTreeNode, after: After) Node {
        return .{ .ptr = &node, .after = after };
    }
};

debug: ?DebugInfo = null,
groups: []const []const Node = &.{},
match: []const (*const MatchFn) = &.{},
build: ?(*const BuildFn) = null, //Called when a node is matched
after: After = .none,

const DEBUG_MATCH = true;
fn debugPrint(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG_MATCH) std.debug.print(fmt, args);
}

fn printstack(loopbackStack: std.ArrayList(StackValue)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        if (item.ptr.debug) |debug| std.debug.print("[{s}]", .{debug.label}) else std.debug.print("[?]", .{});
    }
    std.debug.print("\n", .{});
}

pub fn isMatch(node: SyntaxTreeNode, tokens: [][]const u8) MatchError![][]const u8 {
    if (node.match.len == 0) return &.{};
    if (node.debug) |debug| {
        debugPrint("matching '{s}' \n", .{debug.label});
    }

    var result_tokens = tokens;
    var total_consumed: usize = 0;

    for (node.match) |match| {
        const consumed = match(result_tokens) catch |err| {
            debugPrint(" => N\n", .{});
            return err;
        };
        total_consumed += consumed;
        debugPrint("({})", .{consumed});
        result_tokens = result_tokens[consumed..];
    }

    debugPrint(" => Y\n", .{});
    return tokens[0..total_consumed];
}

const StackValue = struct {
    ptr: *const SyntaxTreeNode,
    group_i: usize = 0,
    node_i: isize = -1,
    allowError: bool = false,
};

pub fn traverse(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
    var tokens = start_tokens;

    var stack = std.ArrayList(StackValue).initCapacity(gpa, 32) catch @panic("OOM");
    defer stack.deinit(gpa);
    stack.append(ctx.gpa, .{ .ptr = &start_node }) catch @panic("OOM");

    loop: while (true) {
        const current = stack.getLast();

        if (current.ptr.debug) |debug| std.debug.print("current {s}\n", .{debug.label});
        printstack(stack);

        if (current.ptr.groups.len == 0) {
            backtrack: while (true) {
                _ = stack.pop();
                const previous = stack.getLast();
                var after = previous.ptr.groups[previous.group_i][@intCast(previous.node_i)].after;

                if (after == .inherit) {
                    after = previous.ptr.after;
                }

                switch (after) {
                    .inherit => unreachable,
                    .end => return,
                    .none => continue :backtrack,
                    .loop => {
                        stack.items[stack.items.len - 1].node_i = -1;
                        continue :loop;
                    },
                    .next => {
                        stack.items[stack.items.len - 1].group_i += 1;
                        stack.items[stack.items.len - 1].node_i = -1;
                        continue :loop;
                    },
                    .prev => {
                        stack.items[stack.items.len - 1].group_i -= 1;
                        stack.items[stack.items.len - 1].node_i = -1;
                        continue :loop;
                    },
                }
            }
        }

        for (current.ptr.groups[current.group_i], @intCast(current.node_i + 1)..) |next, i| {
            const result = next.ptr.isMatch(tokens);

            if (result) |matched_tokens| {
                if (next.ptr.build) |build| try build(ctx, matched_tokens);
                tokens = tokens[matched_tokens.len..];
                stack.items[stack.items.len - 1].node_i = @intCast(i);
                stack.append(gpa, .{ .ptr = next.ptr, .allowError = next.allowError }) catch @panic("OOM");
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
            _ = stack.pop();
        } else {
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

pub const jump = SyntaxTreeNode{ .loopback = .Jump };
pub const jumpl = &.{SyntaxTreeNode{ .loopback = .Jump }};
