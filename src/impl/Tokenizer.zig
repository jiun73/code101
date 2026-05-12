const std = @import("std");
const log = @import("log.zig");
const uni = @import("unicode.util.zig");

const CharFamilyType = struct {
    codepoints: []const []const u8,
    discard: bool = false,
    allowRepeat: bool = false,
    codeBlock: bool = false,
};

const charTypes = [_]CharFamilyType{
    .{ .codepoints = uni.utf8ListComptime("\n \r"), .discard = true, .allowRepeat = true },
    .{ .codepoints = uni.utf8ListComptime("\"\""), .codeBlock = true },
    .{ .codepoints = uni.utf8ListComptime("«»"), .codeBlock = true },
    .{ .codepoints = uni.utf8ListComptime("()"), .discard = true, .allowRepeat = true, .codeBlock = true },
    .{ .codepoints = uni.utf8ListComptime("-"), .allowRepeat = true },
    .{ .codepoints = uni.utf8ListComptime(":") },
    .{ .codepoints = uni.utf8ListComptime(";") },
    .{ .codepoints = uni.utf8ListComptime(".") },
    .{ .codepoints = uni.utf8ListComptime(",") },
    .{ .codepoints = uni.utf8ListComptime("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZéèà'ÉÈÀêÊ"), .allowRepeat = true },
    .{ .codepoints = uni.utf8ListComptime("0123456789"), .allowRepeat = true },
};

pub fn isOneOf(codepoint: []const u8, list: []const []const u8) bool {
    for (list) |item| {
        if (std.mem.eql(u8, item, codepoint)) return true;
    }
    return false;
}

pub fn flatten(codepointArr: []const []const u8) []const u8 {
    var len: usize = 0;
    for (codepointArr) |c| {
        len += c.len;
    }
    var token: []const u8 = codepointArr[0][0..0];
    token.len = len;
    return token;
}

pub fn getFamily(codepoint: []const u8) ?*const CharFamilyType {
    for (&charTypes) |*charType| {
        if (charType.codeBlock) {
            if (std.mem.eql(u8, codepoint, charType.codepoints[0])) return charType;
        } else if (isOneOf(codepoint, charType.codepoints)) {
            return charType;
        }
    }
    return null;
}

pub const TokenizerError = error{InvalidChar};

pub fn tokenize(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8) TokenizerError!std.ArrayList([]const u8) {
    var tokens = std.ArrayList([]const u8).initCapacity(gpa, 128) catch @panic("OOM");

    const codepoints = uni.strToCodepointSliceListAlloc(gpa, source) catch @panic("invalid UTF8");
    defer gpa.free(codepoints);

    const progress = progressNode.start("Tokenize", source.len);

    var i: usize = 0;
    var s: usize = 0;

    var cfam: ?*const CharFamilyType = getFamily(codepoints[0]);

    //log.println("char: {s}", .{codepoints[0..1]}, .Tokenize);
    //log.println("fam: '{any}'", .{cfam}, .Tokenize);

    while (i < codepoints.len) {
        const c = codepoints[i];

        //log.println("char: '{s}' ", .{c}, .Tokenize);

        const fam = getFamily(c);

        if (fam == null) {
            //log.println("code: {s} {x}", .{ c, i }, .Tokenize);
            return TokenizerError.InvalidChar;
        }

        if (cfam == null) {
            cfam = fam;
            i += 1;
            continue;
        }

        if (cfam.?.codeBlock) {
            while (!std.mem.eql(u8, codepoints[i], cfam.?.codepoints[1])) {
                i += 1;
            }
            if (!cfam.?.discard) {
                i += 1;
                const token_codepoints = codepoints[s..i];
                const token = flatten(token_codepoints);
                log.println("[{s}]", .{token}, .Tokenize);
                i -= 1;
                progress.setCompletedItems(i);
                tokens.append(gpa, token) catch @panic("OOM");
            }
            cfam = null;
            s = i + 1;
            i += 1;
            continue;
        }

        if ((!cfam.?.allowRepeat) or cfam != fam) {
            if (!cfam.?.discard) {
                const token_codepoints = codepoints[s..i];
                const token = flatten(token_codepoints);
                log.println("[{s}]", .{token}, .Tokenize);
                progress.setCompletedItems(i);
                tokens.append(gpa, token) catch @panic("OOM");
            }

            cfam = fam;
            s = i;
            i += 1;
        } else i += 1;
    }

    if (!cfam.?.discard) {
        const token_codepoints = codepoints[s..i];
        const token = flatten(token_codepoints);
        progress.setCompletedItems(i);
        log.println("[{s}]", .{token}, .Tokenize);
        tokens.append(gpa, token) catch @panic("OOM");
    }

    progress.end();

    return tokens;
}
