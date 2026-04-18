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

debug: ?DebugInfo = null,
match: []const (*const MatchFn) = &.{},
build: ?(*const BuildFn) = null,
build_after: ?(*const BuildFn) = null,
tokens: TokenUsageType = .Current,
next: []const SyntaxTreeNode = &.{},
after: []const SyntaxTreeNode = &.{},
loopback: LoopType = .None,

const DEBUG_MATCH = true;
fn debugPrint(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG_MATCH) std.debug.print(fmt, args);
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

// fn traverseNodes2(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
//     var tokens = start_tokens;
//     var stack = std.ArrayList(*SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
//     defer stack.deinit(gpa);
//     stack.append(ctx.gpa, &start_node);
// }

fn traverseNodes(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: [][]const u8) !void {
    var tokens = start_tokens;
    var currentNode: SyntaxTreeNode = start_node;
    var loopbackStack = std.ArrayList(SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
    defer loopbackStack.deinit(gpa);

    var savedTokensStack = std.ArrayList([][]const u8).initCapacity(gpa, 32) catch @panic("OOM");
    defer savedTokensStack.deinit(gpa);

    mainloop: while (true) {
        ctx.progressNode.setCompletedItems(tokens.len);
        if (currentNode.debug != null) {
            debugPrint("current node: {s} ({any} tokens)\n", .{ currentNode.debug.?, tokens.len });
        }

        if (tokens.len == 0) {
            if (currentNode.loopback == .Master or currentNode.loopback == .End) {
                return;
            } else {
                return SyntaxTreeNode.MatchError.OutOfTokens;
            }
        }

        try switch (currentNode.loopback) {
            .After => {
                debugPrint("after:{?s} - ", .{currentNode.debug});
                var copy = currentNode;
                copy.next = copy.after;
                copy.tokens = .Current;
                copy.debug = .{ .label = copy.debug.?.label_after, .label_after = copy.debug.?.label_after };
                copy.loopback = .None;
                try loopbackStack.append(gpa, copy);
                //printstack(loopbackStack);
            },
            .JumpAfter => {
                debugPrint("jumpafter:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, SyntaxTreeNode{
                    .next = &.{
                        SyntaxTreeNode{
                            .loopback = .Jump,
                            .build = currentNode.build_after,
                        },
                    },
                });
                //printstack(loopbackStack);
            },
            .Self => {
                debugPrint("self:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, currentNode);
                //printstack(loopbackStack);
            },
            .Master => loopbackStack.append(gpa, currentNode),
            .Jump => {
                const last = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;
                currentNode = last;

                if (currentNode.loopback == .After) {
                    currentNode.next = currentNode.after;
                }
                debugPrint("jump => [{?s}] - ", .{currentNode.debug});
                //printstack(loopbackStack);
                continue :mainloop;
            },
            .JumpPrevious => {
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;

                debugPrint("popjump => [{?s}] - ", .{currentNode.debug});
                //printstack(loopbackStack);
                continue :mainloop;
            },
            .Jump2Previous => {
                _ = loopbackStack.pop();
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return TraversalError.InvalidStackPop;

                debugPrint("popjump => [{?s}] - ", .{currentNode.debug});
                //printstack(loopbackStack);
                continue :mainloop;
            },
            .None => {},
            .End => {},
            .BranchAfter => {},
        };

        for (currentNode.next, 0..) |*next, i| {
            const result_err = next.*.isMatch(tokens);

            if (result_err) |result| {
                if (currentNode.loopback == .BranchAfter) {
                    var copy = currentNode;
                    copy.next = copy.after[i..];
                    copy.tokens = .Current;
                    copy.debug = null;
                    copy.loopback = .None;
                    try loopbackStack.append(gpa, copy);
                    debugPrint("branch #{} => [{?s}] - ", .{ i, copy.debug });
                    //printstack(loopbackStack);
                }
                const tok_before = tokens;
                tokens = tokens[result.len..];
                currentNode = next.*;
                if (currentNode.build != null) {
                    if (currentNode.tokens == .Saved) {
                        const toks = savedTokensStack.pop() orelse @panic("out of saved tokens");
                        const err = currentNode.build.?(ctx, toks);
                        err catch {
                            ctx.printLineError(@ptrCast(tok_before[0].ptr));
                            return err;
                        };
                    } else {
                        const err = currentNode.build.?(ctx, result);
                        err catch {
                            ctx.printLineError(@ptrCast(tok_before[0].ptr));
                            return err;
                        };
                    }
                }
                if (currentNode.tokens == .Save) {
                    try savedTokensStack.append(gpa, result);
                }
                continue :mainloop;
            } else |_| {
                debugPrint("checking next...\n", .{});
                continue;
            }
        }

        if (currentNode.debug != null) {
            debugPrint("no match found for node {s}. exiting\n", .{currentNode.debug.?});
        }

        ctx.printLineError(@ptrCast(tokens[0].ptr));

        return SyntaxTreeNode.MatchError.DoesNotMatch;
    }
}

pub const jump = SyntaxTreeNode{ .loopback = .Jump };
pub const jumpl = &.{SyntaxTreeNode{ .loopback = .Jump }};
