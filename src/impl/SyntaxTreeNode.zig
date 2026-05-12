const std = @import("std");
const log = @import("log.zig");
const fns = @import("fns.zig");
const Context = @import("Context.zig");

pub const SyntaxTreeNode = @This();

pub const MatchTrue = union(enum) { match: void, consume: usize };
pub const MatchFalse = union(enum) { doesNotMatch: void, indexDoesNotMatch: usize, outOfTokens: void };
pub const Match = union(enum) { true: MatchTrue, false: MatchFalse };
pub const MatchFnRet = Match;
pub const MatchFn = fn ([]const []const u8) MatchFnRet;
pub const BuildFn = fn (builder: *Context, []const []const u8) anyerror!void;
pub const BuildFnNoTokens = fn (builder: *Context) anyerror!void;
pub const BuildFnSingleToken = fn (builder: *Context, []const u8) anyerror!void;

pub const Builder = struct {
    fun: (*const BuildFn),

    pub fn tok(fun: BuildFn) Builder {
        return .{ .fun = fun };
    }

    pub fn get(fun: BuildFnSingleToken, comptime token_index: comptime_int) Builder {
        const T = struct {
            pub fn f(ctxArg: *Context, tokens: []const []const u8) anyerror!void {
                const token = tokens[token_index];
                try fun(ctxArg, token);
            }
        };

        return .{ .fun = T.f };
    }

    pub fn ctx(fun: BuildFnNoTokens) Builder {
        const T = struct {
            pub fn f(ctxArg: *Context, _: []const []const u8) anyerror!void {
                try fun(ctxArg);
            }
        };

        return .{ .fun = T.f };
    }
};

pub const MatchError = error{ OutOfTokens, DoesNotMatch };
const TraversalError = error{InvalidToken};

const DebugInfo = struct {
    lbl: [:0]const u8,
    label_after: [:0]const u8,

    pub fn label(comptime lbl: [:0]const u8) DebugInfo {
        return .{ .lbl = lbl, .label_after = "@" ++ lbl };
    }
};

const Matcher = struct {
    fns: []const (*const MatchFn),

    pub fn any() Matcher {
        return .{ .fns = &.{} };
    }

    pub fn str(comptime fmt: []const u8) Matcher {
        return .{ .fns = fns.eql(fmt) };
    }
};

//Actione est utlisé par SyntaxTreeNode notamment
//pour controler le comportement d'une node lorsqu'elle est 'matché',
const Action = union(enum) {
    none: void, //Retourne à la dernière node du stack
    restart: void, //Recommence la node depuis le tout premier groupe
    last: void, //Va au tout dernier groupe
    loop: void, //Recommence le groupe courant à la première branche
    next: usize, //Aller au prochain groupe après avoir retourné de la node
    prev: usize, //Aller au précédent groupe après avoir retourné de la node
    detour: void, //Tente de match la node. passe à la prochaine branche si rien n'est match
};

pub const Branch = struct {
    ptr: *const SyntaxTreeNode = &SyntaxTreeNode{},
    cancelDeferOffset: bool = false,
    allowError: bool = false,
    afterAction: Action = .none,

    pub fn any() Branch {
        return .{ .ptr = &SyntaxTreeNode{} };
    }

    pub fn err(node: SyntaxTreeNode, action: Action) Branch {
        return .{ .ptr = &node, .allowError = true, .afterAction = action };
    }

    pub fn leaf(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node };
    }

    pub fn build(bld: Builder, action: Action) Branch {
        return .{ .afterAction = action, .ptr = &SyntaxTreeNode{ .building = bld } };
    }

    pub fn loop(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .loop };
    }

    pub fn restart(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .restart };
    }

    pub fn last() Branch {
        return .{ .ptr = &SyntaxTreeNode{}, .afterAction = .last };
    }

    pub fn exit() Branch {
        return .{};
    }

    pub fn cancelDefer() Branch {
        return .{ .cancelDeferOffset = true };
    }

    pub fn next(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .{ .next = 0 } };
    }

    pub fn nextSkip(node: SyntaxTreeNode, n: usize) Branch {
        return .{ .ptr = &node, .afterAction = .{ .next = n } };
    }

    pub fn detour(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .detour };
    }

    pub fn prev(node: SyntaxTreeNode) Branch {
        return .{ .ptr = &node, .afterAction = .{ .prev = 0 } };
    }

    pub fn initA(node: SyntaxTreeNode, after: Action) Branch {
        return .{ .ptr = &node, .afterAction = after };
    }
};

debug: ?DebugInfo = null,

// Définit le flow de controle d'une node.
// Lorsq'elle est match, on traverse toutes le branches d'une node
// Il y a plusieurs groupes de pluieurs branches.
// On commence avec le tout premier groupe, vérifiant si chauqe branch match une par une
// Au moins une branche dans le groupe doit être match, sinon c'est une erreur
// selon l'action de la branche, on peut passer à la prochaine branche, faire une boucle, retourner à la dernier node, etc.
branches: []const []const Branch = &.{},

// Liste de fonctions, appellées dans l'ordre, qui décident si les tokens sont valide ou pas pour qu'on match la node
matching: Matcher = .any(), //if matchFns.len == 0 then node is considered 'virtual'. Failure to match the first branch will result in returning to first non-virtual node in the stack

//cas spécial qui permet d'annuler la consommation de tokens. utile dans des cas ou la syntaxe est ambigue
//On annule en utlisant les branches, ou si one node est match, les tokens sont consommé comme normal
deferConsume: bool = false,
building: ?Builder = null, //Called when a node is matched

pub fn match(comptime str: []const u8) SyntaxTreeNode {
    return .{ .matching = .str(str) };
}

fn printstack(loopbackStack: std.ArrayList(StackRef)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        if (item.node.debug) |debug| std.debug.print("[{s}{s}{}:{}]", .{ debug.lbl, if (item.allowError) "!" else "", item.branch_i, item.group_i }) else std.debug.print("[?]", .{});
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

// Compare les tokens restant, essayant de savoir si ils sont un match en utlisant les fontions définits par l'utilisateur
// Regarde généralement les tokens en haut de la pile en en consomme un certain nombre
pub fn isMatch(node: SyntaxTreeNode, tokens: []const []const u8) MatchFnRet {
    //if (node.matchFns.len == 0) return .{ .true = .match };
    if (node.debug) |debug| {
        log.println("matching '{s}' ", .{debug.lbl}, .MatchingVerbose);
    }

    var result_tokens = tokens;
    var total_consumed: usize = 0;

    for (node.matching.fns) |matchFn| {
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
    node: *const SyntaxTreeNode,
    matched: usize = 0,
    group_i: usize = 0,
    branch_i: usize = std.math.maxInt(usize),
};

// Fonction principale qui permet de navigueur l'arbre de syntaxe
// L'entièreté de la syntaxe est gouverné par cette fonction
// On utilise un stack afin d'éviter la récursion
pub fn traverse(start_node: SyntaxTreeNode, ctx: *Context, gpa: std.mem.Allocator, start_tokens: []const []const u8) !void {
    var tokens = start_tokens;

    var stack = std.ArrayList(StackRef).initCapacity(gpa, 32) catch @panic("OOM");
    defer stack.deinit(gpa);
    stack.append(ctx.gpa, .{ .node = &start_node }) catch @panic("OOM");

    var tokenOffset: usize = 0;

    loop: while (true) {
        tab(stack.items, false);
        const current = stack.getLastOrNull() orelse return;

        if (current.node.branches.len == 0) {
            var first = true;
            backtrack: while (true) {
                _ = stack.pop();
                if (!first) {
                    tab(stack.items[0..stack.items.len], true);
                    log.println("┘", .{}, .Traversal);
                } else {
                    first = false;
                }

                if (stack.items.len == 0) return;

                var previous = &stack.items[stack.items.len - 1];
                const branch = previous.node.branches[previous.group_i][previous.branch_i];
                const action = branch.afterAction;

                //log.println("backtrack {s} (i:{};group:{})", .{ if (previous.ptr.debug) |debug| debug.label else "?", previous.node_i, previous.group_i }, .Traversal);
                //tab(stack.items[0..(stack.items.len - 1)], false);
                tab(stack.items[0..(stack.items.len - 1)], false);

                if (branch.cancelDeferOffset) {
                    tokenOffset = 0;
                    log.println("cancelled defer", .{}, .Traversal);
                }

                switch (action) {
                    .none => {
                        //tab(stack.items[0..(stack.items.len - 1)], true);
                        //log.ln(.Traversal);
                        //log.println("┘", .{}, .Traversal);
                        continue :backtrack;
                    },
                    .restart => {
                        previous.group_i = 0;
                        previous.branch_i = std.math.maxInt(usize);
                        log.println("#", .{}, .Traversal);
                        continue :loop;
                    },
                    .last => {
                        previous.group_i = previous.node.branches.len - 1;
                        previous.branch_i = std.math.maxInt(usize);
                        log.println("*", .{}, .Traversal);
                        continue :loop;
                    },
                    .detour => {
                        log.println("║", .{}, .Traversal);
                        //stack.items[stack.items.len - 1].node_i -= 1;
                        continue :loop;
                    },
                    .loop => {
                        log.println("@", .{}, .Traversal);
                        previous.branch_i = std.math.maxInt(usize);
                        continue :loop;
                    },
                    .next => |n| {
                        previous.group_i += 1 + n;
                        previous.branch_i = std.math.maxInt(usize);
                        log.println("{}", .{stack.items[stack.items.len - 1].group_i}, .Traversal);
                        continue :loop;
                    },
                    .prev => |n| {
                        previous.group_i -= 1 + n;
                        previous.branch_i = std.math.maxInt(usize);
                        log.println("{}", .{stack.items[stack.items.len - 1].group_i}, .Traversal);
                        continue :loop;
                    },
                }
            }
        }

        const ni = (current.branch_i +% 1);
        const sub = current.node.branches[current.group_i][ni..];

        for (sub, ni..) |next, i| {
            //log.print("i:{} ", .{i}, .Traversal);
            const result = next.ptr.isMatch(tokens[tokenOffset..]);

            switch (result) {
                .true => |trueval| {
                    stack.items[stack.items.len - 1].matched += 1;

                    var consumed_count: usize = 0;
                    switch (trueval) {
                        .consume => |consumed| {
                            consumed_count = consumed;
                        },
                        else => {},
                    }

                    const matched_tokens = tokens[tokenOffset..(tokenOffset + consumed_count)];

                    if (next.ptr.building) |builder| try builder.fun(ctx, matched_tokens);

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

                    stack.items[stack.items.len - 1].branch_i = i;
                    if (next.ptr.branches.len > 0) {
                        tab(stack.items, true);
                        log.println("{s}", .{if (next.ptr.debug) |debug| debug.lbl else "┐"}, .Traversal);
                    }

                    stack.append(gpa, .{ .node = next.ptr }) catch @panic("OOM");
                    continue :loop;
                },
                .false => continue,
            }
        }

        if (current.matched == 0 and current.node.matching.fns.len == 0) {
            if (tokenOffset > 0) log.println("defer cancel on error", .{}, .Traversal);
            tokenOffset = 0;
            backtrack: while (true) {
                tab(stack.items, false);
                const prev = stack.pop() orelse break;
                const last = &stack.items[stack.items.len - 1];
                const branch = last.node.branches[last.group_i][last.branch_i];
                log.println("no match: virtual node, so returning to {s} ({})", .{ if (last.node.debug) |dgb| dgb.lbl else "?", branch.allowError }, .Traversal);
                log.println("err:{} action:{} matched:{}", .{ branch.allowError, branch.afterAction, last.matched }, .Traversal);
                log.println("{}:{}", .{ last.group_i, last.branch_i }, .Traversal);
                if (branch.afterAction != .detour and !branch.allowError and prev.matched <= 1) {
                    last.matched = 0;
                    continue :backtrack;
                } else break;
            }

            continue :loop;
        }

        std.debug.print("\n\nErreur de compilation!\n", .{});
        ctx.printLineError(@ptrCast(tokens[0].ptr));
        return MatchError.DoesNotMatch;
    }
}
