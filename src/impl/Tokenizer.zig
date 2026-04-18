const std = @import("std");
const util = @import("tok.util.zig");

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
    .{ .chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZéà'ÉÀêÊ", .allowRepeat = true },
    .{ .chars = "0123456789", .allowRepeat = true },
};

pub fn getFamily(char: u8) ?*const CharFamilyType {
    for (&charTypes) |*charType| {
        if (charType.codeBlock) {
            if (char == charType.chars[0]) return charType;
        } else if (util.isoneof(char, charType.chars)) {
            return charType;
        }
    }
    return null;
}

pub const TokenizerError = error{InvalidChar};

const DEBUG_TOKEN = false;
fn debugPrint(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG_TOKEN) std.debug.print(fmt, args);
}

pub fn tokenize(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8) TokenizerError!std.ArrayList([]const u8) {
    var tokens = std.ArrayList([]const u8).initCapacity(gpa, 128) catch @panic("OOM");

    const progress = progressNode.start("Tokenize", source.len);

    var i: usize = 0;
    var s: usize = 0;

    var cfam: ?*const CharFamilyType = getFamily(source[0]);

    debugPrint("char: {s}\n", .{source[0..1]});
    debugPrint("char: {any}\n", .{cfam});

    while (i < source.len) {
        const c = source[i];

        const fam = getFamily(c);

        if (fam == null) {
            debugPrint("code: {x} {x}\n", .{ c, i });
            return TokenizerError.InvalidChar;
        }

        if ((cfam == null)) {
            cfam = fam;
            i += 1;
            continue;
        }

        if (cfam.?.codeBlock) {
            while (source[i] != cfam.?.chars[1]) {
                i += 1;
            }
            if (!cfam.?.discard) {
                i += 1;
                const token = source[s..i];
                debugPrint("[{s}]\n", .{token});
                i -= 1;
                progress.setCompletedItems(i);
                tokens.append(gpa, token) catch @panic("OOM");
            }
            cfam = null;
            s = i;
            i += 1;
            continue;
        }

        if ((!cfam.?.allowRepeat) or cfam != fam) {
            if (!cfam.?.discard) {
                const token = source[s..i];
                debugPrint("[{s}]\n", .{token});
                progress.setCompletedItems(i);
                tokens.append(gpa, token) catch @panic("OOM");
            }

            cfam = fam;
            s = i;
            i += 1;
        } else i += 1;
    }

    if (!cfam.?.discard) {
        const token = source[s..i];
        debugPrint("[{s}]\n", .{token});
        progress.setCompletedItems(i);
        tokens.append(gpa, token) catch @panic("OOM");
    }

    progress.end();

    return tokens;
}
