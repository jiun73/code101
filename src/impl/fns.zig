const std = @import("std");
const log = @import("log.zig");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");

pub fn matchConstTokens(comptime const_tokens: []const []const u8) SyntaxTreeNode.MatchFn {
    const Ret = struct {
        fn f(tokens: [][]const u8) SyntaxTreeNode.MatchFnRet {
            if (tokens.len < const_tokens.len) return .{ .false = .outOfTokens };
            for (const_tokens, 0..) |const_token, i| {
                log.print("{s}[{s}] ", .{ tokens[i], const_token }, .MatchingVerbose);
                if (!std.mem.eql(u8, const_token, tokens[i])) return .{ .false = .{ .indexDoesNotMatch = i } };
            }

            return .{ .true = .{ .consume = const_tokens.len } };
        }
    };

    return Ret.f;
}

pub fn matchConstTokensStr(comptime fmt: []const u8) SyntaxTreeNode.MatchFn {
    comptime {
        var cnt = 1;
        for (fmt) |c| {
            if (c == ' ') {
                cnt += 1;
            }
        }

        var tokens: [cnt][]const u8 = undefined;
        var off = 0;
        var id = 0;
        for (fmt, 0..) |c, i| {
            if (c == ' ') {
                tokens[id] = fmt[off..i];
                off = i + 1;
                id += 1;
            }
        }
        tokens[id] = fmt[off..];
        const final = tokens;
        return matchConstTokens(&final);
    }
}

//delcarer un numbre enter [varlbl]
//aaa [bbb] ccc
pub fn eql(comptime fmt: []const u8) []const (*const SyntaxTreeNode.MatchFn) {
    comptime {
        var cnt = 1;
        for (fmt) |c| {
            if (c == ' ') {
                cnt += 1;
            }
        }

        var tokens: [cnt][]const u8 = undefined;
        var off = 0;
        var id = 0;
        for (fmt, 0..) |c, i| {
            if (c == ' ') {
                tokens[id] = fmt[off..i];
                off = i + 1;
                id += 1;
            }
        }
        tokens[id] = fmt[off..];
        var fns: []const (*const SyntaxTreeNode.MatchFn) = &.{};
        var run: []const u8 = "";
        for (tokens) |token| {
            if (token[0] == '[' and token[token.len - 1] == ']') {
                if (run.len != 0) {
                    fns = fns ++ .{matchConstTokensStr(run[0 .. run.len - 1])};
                    run = "";
                }

                const control = token[1 .. token.len - 1];

                if (std.mem.eql(u8, control, "var")) {
                    fns = fns ++ .{single(variableName)};
                } else if (std.mem.eql(u8, control, "str")) {
                    fns = fns ++ .{single(stringValue)};
                } else if (std.mem.eql(u8, control, "sectionlbl")) {
                    fns = fns ++ .{single(sectionLabel)};
                } else if (std.mem.eql(u8, control, "int")) {
                    fns = fns ++ .{single(integerValue)};
                } else @compileError("invalid fmt");
            } else {
                run = run ++ token ++ " ";
            }
        }

        if (run.len != 0) {
            fns = fns ++ .{matchConstTokensStr(run[0 .. run.len - 1])};
        }

        return fns;
    }
}

pub fn sectionLabel(str: []const u8) bool {
    log.print("{s}[sectionLabel]", .{str}, .MatchingVerbose);
    if (str.len < 2) return false;
    if (std.mem.eql(u8, str, "principale")) return true;
    if (stringValue(str)) return true;
    return false;
}

pub fn stringValue(str: []const u8) bool {
    log.print("{s}[str]", .{str}, .MatchingVerbose);

    var view = std.unicode.Utf8View.init(str) catch @panic("invalid UTF8");
    var iter = view.iterator();
    const count = std.unicode.utf8CountCodepoints(str) catch @panic("invalid UTF8");

    if (count == 0) return false;

    var first: u21 = undefined;
    var last: u21 = undefined;

    var i: usize = 0;
    while (iter.nextCodepoint()) |codepoint| {
        if (i == count - 1) {
            last = codepoint;
        }

        if (i == 0) {
            first = codepoint;
        }

        i += 1;
    }

    return (first == '"' and last == '"') or (first == '«' and last == '»');
}

pub fn variableName(str: []const u8) bool {
    return (str.len == 1) and (std.mem.indexOfScalar(u8, "0123456789", str[0]) == null);
}

pub fn integerValue(str: []const u8) bool {
    for (str) |c| {
        if (std.mem.indexOfScalar(u8, "0123456789", c) == null) return false;
    }
    return true;
}

pub fn single(comptime strf: fn ([]const u8) bool) SyntaxTreeNode.MatchFn {
    const Ret = struct {
        pub fn f(tokens: []const []const u8) SyntaxTreeNode.MatchFnRet {
            if (tokens.len == 0) return .{ .false = .outOfTokens };
            const token = tokens[0];

            if (strf(token)) {
                return .{ .true = .{ .consume = 1 } };
            } else {
                return .{ .false = .doesNotMatch };
            }
        }
    };

    return Ret.f;
}

pub fn matchEnd(tokens: []const []const u8) SyntaxTreeNode.MatchFnRet {
    if (tokens.len == 0) return .{ .true = .match };
    return .{ .false = .doesNotMatch };
}
