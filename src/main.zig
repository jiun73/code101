const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");

const CharFamilyType = struct {
    discard: bool,
    allowRepeat: bool,
    codeBlock: bool,
    blockEnd: ?u8 = null,
    chars: []const u8,
};

const charTypes: [10]CharFamilyType = .{
    .{ .discard = true, .allowRepeat = true, .codeBlock = false, .chars = "\n \r" },
    .{ .discard = true, .allowRepeat = true, .codeBlock = true, .chars = "\"", .blockEnd = '"' },
    .{ .discard = true, .allowRepeat = true, .codeBlock = true, .chars = "(", .blockEnd = ')' },
    .{ .discard = false, .allowRepeat = true, .codeBlock = false, .chars = "-" },
    .{ .discard = false, .allowRepeat = false, .codeBlock = false, .chars = ":" },
    .{ .discard = false, .allowRepeat = false, .codeBlock = false, .chars = ";" },
    .{ .discard = false, .allowRepeat = false, .codeBlock = false, .chars = "." },
    .{ .discard = false, .allowRepeat = false, .codeBlock = false, .chars = "," },
    .{ .discard = false, .allowRepeat = true, .codeBlock = false, .chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZéà'ÉÀ" },
    .{ .discard = false, .allowRepeat = true, .codeBlock = false, .chars = "0123456789" },
};

const sectionDeclaration = .{ "---", "section", "[*sec]", "---" };
const sectionEnd = .{ "---", "---" };
const argDeclStart = .{ "Prérequis", ":" };
const argDeclStmnt = .{ "-", "[*var]", ",", "un", "[*type]", ";" };
const retVal = .{ "Résultat", ":", "-", "[*type]", ";" };
const stepDecl = .{ "Étape", "[*num]", ":" };

pub fn sectionLabel(str: [][]const u8) ?u8 {
    if (str.len < 2) return null;
    if (std.mem.eql(u8, str[0], "principal")) return 1;
    if (str[0][0] == '"' and str[0][str[0].len - 1] == '"') return 1;
    return null;
}

pub fn matchTemp(_: []const u8) bool {
    return true;
}

pub fn matchParagraph(_: []const u8) bool {
    return true;
}

pub fn any(_: [][]const u8) ?u8 {
    return 0;
}

const ASTNode = struct {};

const ASTBuilder = struct {
    gpa: std.mem.Allocator,
};

const masterNode: SyntaxTreeNode = .{
    .next = &.{
        sectionNode,
    },
};

pub fn ParagrahNode(comptime next: []const SyntaxTreeNode) type {
    return .{
        .match = SyntaxTreeNode.Eq("---").fun,
        .type = .Section,
        .next = &.{},
    };
}

const sectionNode: SyntaxTreeNode = .{
    .match = SyntaxTreeNode.Eq("---").fun,
    .type = .Section,
    .next = &.{
        .{
            .match = SyntaxTreeNode.Eq("section").fun,
            .next = &.{
                .{
                    .match = sectionLabel,
                    .next = &.{
                        .match = SyntaxTreeNode.Eq("---").fun,
                        .next = &.{
                            .{
                                .match = matchParagraph,
                                .next = &.{
                                    .match = SyntaxTreeNode.Eq("---").eq,
                                    .next = &.{ .match = SyntaxTreeNode.Eq("---").eq, .next = ParagrahNode(&.{}) },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
};

pub fn traverseNode(node: SyntaxTreeNode, tokens: [][]const u8) !u8 {
    for (node.next) |next| {
        // next.
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
        if (isoneof(char, charType.chars)) return charType;
    }
    return null;
}

pub fn tokenize(file: []u8, gpa: std.mem.Allocator) void {
    var i: usize = 0;
    var s: usize = 0;

    var tokens = std.ArrayList([]const u8).initCapacity(gpa, 128) catch @panic("OOM");
    defer tokens.deinit(gpa);

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
                while (file[i] != cfam.?.blockEnd) {
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
        tokenize(file, gpa);
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
