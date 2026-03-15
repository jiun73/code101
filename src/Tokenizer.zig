const std = @import("std");

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

pub const TokenizerError = error{InvalidChar};

pub fn tokenize(progress: std.Progress.Node, file: []const u8, tokens: *std.ArrayList([]const u8), gpa: std.mem.Allocator) TokenizerError!void {
    var i: usize = 0;
    var s: usize = 0;

    var cfam: ?*const CharFamilyType = getfam(file[0]);

    //std.debug.print("char: {s}\n", .{file[0..1]});
    //std.debug.print("char: {any}\n", .{cfam});

    while (i < file.len) {
        const c = file[i];

        const fam = getfam(c);

        if (fam == null) {
            std.debug.print("code: {x} {x}\n", .{ c, i });
            return TokenizerError.InvalidChar;
        }

        if ((cfam == null)) {
            cfam = fam;
            i += 1;
            continue;
        }

        if (cfam.?.codeBlock) {
            while (file[i] != cfam.?.chars[1]) {
                i += 1;
            }
            if (!cfam.?.discard) {
                i += 1;
                const token = file[s..i];
                //std.debug.print("[{s}]\n", .{token});
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
                const token = file[s..i];
                //std.debug.print("[{s}]\n", .{token});
                progress.setCompletedItems(i);
                tokens.append(gpa, token) catch @panic("OOM");
            }

            cfam = fam;
            s = i;
            i += 1;
        } else i += 1;
    }

    if (!cfam.?.discard) {
        const token = file[s..i];
        //std.debug.print("[{s}]\n", .{token});
        progress.setCompletedItems(i);
        tokens.append(gpa, token) catch @panic("OOM");
    }
}
