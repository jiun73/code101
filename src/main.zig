const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");
const nodes = @import("nodes.zig");
const AST = @import("ast.zig");
const ex = @import("ex.zig");

const CharFamilyType = struct {
    chars: []const u8,
    discard: bool = false,
    allowRepeat: bool = false,
    codeBlock: bool = false,
};

const charTypes: [10]CharFamilyType = .{
    .{ .chars = "\n \r", .discard = true, .allowRepeat = true },
    .{ .chars = "\"\"", .codeBlock = true },
    .{ .chars = "()", .discard = true, .allowRepeat = true, .codeBlock = true },
    .{ .chars = "-", .allowRepeat = true },
    .{ .chars = ":" },
    .{ .chars = ";" },
    .{ .chars = "." },
    .{ .chars = "," },
    .{ .chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZéà'ÉÀ", .allowRepeat = true },
    .{ .chars = "0123456789", .allowRepeat = true },
};

const MatchError = error{ OutOfTokens, DoesNotMatch };
const CompilerError = error{ NoLbNextNode, InvalidStackPop };

pub fn isMatchNode(node: SyntaxTreeNode, tokens: [][]const u8) MatchError![][]const u8 {
    if (node.match.len == 0) return &.{};
    if (node.debug != null) {
        std.debug.print("matching '{s}' with \n", .{node.debug.?});
    }

    for (node.match, 0..) |match, i| {
        if (i >= tokens.len) return MatchError.OutOfTokens;
        const tok = tokens[i];
        std.debug.print("[{s}]", .{tok});
        if (!match(tok)) {
            std.debug.print(" => X\n", .{});
            return MatchError.DoesNotMatch;
        }
    }
    std.debug.print(" => Y\n", .{});
    return tokens[0..node.match.len];
}

fn printstack(loopbackStack: std.ArrayList(*const SyntaxTreeNode)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        std.debug.print("[{?s}]", .{item.debug});
    }
    std.debug.print("\n", .{});
}

pub fn traverseNode(b: AST.Builder, startNode: SyntaxTreeNode, startTokens: [][]const u8, gpa: std.mem.Allocator) !void {
    var tokens = startTokens;
    var currentNode: *const SyntaxTreeNode = &startNode;
    var loopbackStack = std.ArrayList(*const SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
    defer loopbackStack.deinit(gpa);

    mainloop: while (true) {
        if (currentNode.debug != null) {
            std.debug.print("current node: {s} ({any} tokens)\n", .{ currentNode.debug.?, tokens.len });
        }

        if (tokens.len == 0) {
            if (currentNode.loopback == .Master or currentNode.loopback == .End) {
                return;
            } else {
                return MatchError.OutOfTokens;
            }
        }

        try switch (currentNode.loopback) {
            .Next => {
                std.debug.print("lbnext:{?s} - ", .{currentNode.lbnext.?.debug});
                try loopbackStack.append(gpa, currentNode.lbnext orelse return CompilerError.NoLbNextNode);
                printstack(loopbackStack);
            },
            .Self => {
                std.debug.print("lb:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, currentNode);
                printstack(loopbackStack);
            },
            .Master => loopbackStack.append(gpa, currentNode),
            .Jump => {
                const last = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;
                currentNode = last;
                std.debug.print("jump => [{?s}] - ", .{currentNode.debug});
                printstack(loopbackStack);
                continue :mainloop;
            },
            .JumpPrevious => {
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;
                std.debug.print("popjump => [{?s}] - ", .{currentNode.debug});
                printstack(loopbackStack);
                continue :mainloop;
            },
            .None => {},
            .End => {},
        };

        for (currentNode.next) |*next| {
            const result_err = isMatchNode(next.*, tokens);

            if (result_err) |result| {
                tokens = tokens[result.len..];
                currentNode = next;
                if (currentNode.build != null) {
                    currentNode.build.?(b, result);
                }
                continue :mainloop;
            } else |_| {
                std.debug.print("checking next...\n", .{});
                continue;
            }
        }

        if (currentNode.debug != null) {
            std.debug.print("no match found for node {s}. exiting\n", .{currentNode.debug.?});
        }

        return MatchError.DoesNotMatch;
    }
}

pub fn isoneof(char: u8, list: []const u8) bool {
    var i: usize = 0;
    while (i < list.len) {
        if (char == list[i]) return true;
        i += 1;
    }
    return false;
}

pub fn getfam(char: u8) ?*const CharFamilyType {
    for (&charTypes) |*charType| {
        if (charType.codeBlock) {
            if (char == charType.chars[0]) return charType;
        } else if (isoneof(char, charType.chars)) {
            return charType;
        }
    }
    return null;
}

pub fn tokenize(file: []u8, tokens: *std.ArrayList([]const u8), gpa: std.mem.Allocator) void {
    var i: usize = 0;
    var s: usize = 0;

    var cfam: ?*const CharFamilyType = null;

    while (i < file.len) {
        const c = file[i];

        const fam = getfam(c);

        if (fam == null) {
            std.debug.print("{x}\n", .{c});
            @panic("invalid char");
        }

        if ((cfam == null)) {
            cfam = fam;
            i += 1;
            continue;
        }

        if ((!cfam.?.allowRepeat) or cfam != fam) {
            if (!cfam.?.discard) {
                const token = file[s..i];
                //std.debug.print("[{s}]\n", .{token});
                tokens.append(gpa, token) catch @panic("OOM");
            }

            cfam = fam;
            s = i;
            i += 1;

            if (cfam.?.codeBlock) {
                while (file[i] != cfam.?.chars[1]) {
                    i += 1;
                }
                i += 1;
                const token = file[s..i];
                i -= 1;
                //std.debug.print("[{s}]\n", .{token});
                tokens.append(gpa, token) catch @panic("OOM");
                cfam = null;
                s = i;
                i += 1;
            }
        } else i += 1;
    }

    if (!cfam.?.discard) {
        const token = file[s..i];
        //std.debug.print("[{s}]\n", .{token});
        tokens.append(gpa, token) catch @panic("OOM");
    }
}

pub fn compile(path: [:0]const u8) !void {
    // 1. Get an allocator
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_allocator.deinit();
    const gpa = general_allocator.allocator();

    const max_file_size = 1024 * 1024; // 1 MB

    const file_contents = std.fs.cwd().readFileAlloc(gpa, path, max_file_size);

    if (file_contents) |file| {
        defer gpa.free(file); // Remember to free the allocated memory
        var tokens = std.ArrayList([]const u8).initCapacity(gpa, 128) catch @panic("OOM");
        defer tokens.deinit(gpa);
        tokenize(file, &tokens, gpa);
        const b = AST.Builder.create(gpa);
        try traverseNode(b, nodes.masterNode, tokens.items, gpa);

        b.module.dump();
    } else |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("Error: File not found", .{});
            return err;
        },
        error.FileTooBig => {
            std.debug.print("Error: File too big. 1mb max per file", .{});
            return err;
        },
        else => {
            std.debug.print("Unhandled error", .{});
            return err;
        },
    }
}

pub fn main() !void {
    ex.e();
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_allocator.deinit();
    const gpa = general_allocator.allocator();

    const args = std.process.argsAlloc(gpa) catch return;
    defer std.process.argsFree(gpa, args);

    std.log.info("alaingular", .{});

    if (args.len == 1) {
        std.log.err("no input specfied.", .{});
        return;
    } else if (args.len == 2) {
        std.log.info("no output specfied. using default output", .{});
        try compile(args[1]);
    }
}
