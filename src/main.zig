const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");

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

pub fn matchTemp(_: []const u8) bool {
    return true;
}

pub fn matchParagraph(_: []const u8) bool {
    return true;
}

const ASTNode = struct {};

const ASTBuilder = struct {
    gpa: std.mem.Allocator,
};

const masterNode: SyntaxTreeNode = .{
    .debug = "master",
    .loopback = .Master,
    .next = &.{
        sectionNode,
    },
};

const paragrahNode = SyntaxTreeNode{
    .debug = "paragrah",
    .match = &.{SyntaxTreeNode.any},
    .loopback = .Self,
    .next = &.{
        SyntaxTreeNode{ .loopback = .JumpPrevious },
    },
};

const sectionNode = SyntaxTreeNode{
    .debug = "section",
    .match = &.{
        fns.Eq("---").fun,
        fns.Eq("section").fun,
        fns.sectionLabel,
        fns.Eq("---").fun,
    },
    .loopback = .Next,
    .next = &.{
        paragrahNode,
    },
    .lbnext = &SyntaxTreeNode{
        .debug = "section_end",
        .next = &.{
            SyntaxTreeNode{
                .match = &.{
                    fns.Eq("---").fun,
                    fns.Eq("---").fun,
                },
                .next = &.{SyntaxTreeNode{ .loopback = .Jump }},
            },
        },
    },
};

const loopbackNodes = .{
    sectionNode,
};

const MatchError = error{ OutOfTokens, DoesNotMatch };

pub fn isMatchNode(node: SyntaxTreeNode, tokens: [][]const u8) MatchError![][]const u8 {
    if (node.match.len == 0) return &.{};
    if (node.debug != null) {
        std.debug.print("matching '{s}' with \n", .{node.debug.?});
    }

    for (node.match, 0..) |match, i| {
        if (i >= tokens.len) return MatchError.OutOfTokens;
        const tok = tokens[i];
        std.debug.print("[{s}]\n", .{tok});
        if (!match(tok)) {
            std.debug.print("not a match\n", .{});
            return MatchError.DoesNotMatch;
        }
    }
    return tokens[0..node.match.len];
}

pub fn traverseNode(startNode: SyntaxTreeNode, startTokens: [][]const u8, gpa: std.mem.Allocator) !void {
    var tokens = startTokens;
    var currentNode: *const SyntaxTreeNode = &startNode;
    var loopbackStack = std.ArrayList(*const SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
    defer loopbackStack.deinit(gpa);

    mainloop: while (true) {
        if (currentNode.debug != null) {
            std.debug.print("current node: {s}\n", .{currentNode.debug.?});
        }

        try switch (currentNode.loopback) {
            .Next => loopbackStack.append(gpa, currentNode.lbnext orelse return MatchError.DoesNotMatch),
            .Self => loopbackStack.append(gpa, currentNode),
            .Master => loopbackStack.append(gpa, currentNode),
            .Jump => {
                std.debug.print("jump\n", .{});
                const last = loopbackStack.pop() orelse return MatchError.DoesNotMatch;
                currentNode = last;
                continue :mainloop;
            },
            .JumpPrevious => {
                std.debug.print("jump previous\n", .{});
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return MatchError.DoesNotMatch;
                continue :mainloop;
            },
            .None => {},
        };

        for (currentNode.next) |next| {
            const result_err = isMatchNode(next, tokens);

            if (result_err) |result| {
                std.debug.print("match found. proceed\n", .{});

                tokens = tokens[result.len..];
                currentNode = &next;
                continue :mainloop;
            } else |err| {
                if (err == error.OutOfTokens) return err;

                std.debug.print("checking next...\n", .{});
                continue;
            }
        }

        if (tokens.len == 0) {
            if (currentNode.loopback == .Master) {
                return;
            } else {
                return MatchError.OutOfTokens;
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

    std.debug.print("{any}\n", .{sectionNode});

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
                std.debug.print("[{s}]\n", .{token});
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
                std.debug.print("[{s}]\n", .{token});
                tokens.append(gpa, token) catch @panic("OOM");
                cfam = null;
                s = i;
                i += 1;
            }
        } else i += 1;
    }

    if (!cfam.?.discard) {
        const token = file[s..i];
        std.debug.print("[{s}]\n", .{token});
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
        try traverseNode(masterNode, tokens.items, gpa);
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
