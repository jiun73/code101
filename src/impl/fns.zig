const std = @import("std");
const tok = @import("tok.util.zig");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");

const DEBUG_EQL = true;
fn debugPrint(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG_EQL) std.debug.print(fmt, args);
}

pub fn matchConstTokens(comptime const_tokens: []const []const u8) SyntaxTreeNode.MatchFn {
    const Ret = struct {
        fn f(tokens: [][]const u8) SyntaxTreeNode.MatchFnRet {
            if (tokens.len < const_tokens.len) return SyntaxTreeNode.MatchError.OutOfTokens;
            for (const_tokens, 0..) |const_token, i| {
                debugPrint("{s}[{s}] ", .{ tokens[i], const_token });
                if (!std.mem.eql(u8, const_token, tokens[i])) return SyntaxTreeNode.MatchError.DoesNotMatch;
            }

            return const_tokens.len;
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
pub fn eql(comptime fmt: []const u8) []const (*const SyntaxTreeNode.MatchFn) {
    comptime {
        return &.{matchConstTokensStr(fmt)};
    }
}

pub fn sectionLabel(str: []const u8) bool {
    debugPrint("{s}[sectionLabel]", .{str});
    if (str.len < 2) return false;
    if (std.mem.eql(u8, str, "principale")) return true;
    if (str[0] == '"' and str[str.len - 1] == '"') return true;
    return false;
}

pub fn stringValue(str: []const u8) bool {
    debugPrint("{s}[str]", .{str});
    return (str[0] == '"' and str[str.len - 1] == '"');
}

pub fn variableName(str: []const u8) bool {
    return (str.len == 1) and !tok.isoneof(str[0], "0123456789");
}

pub fn integerValue(str: []const u8) bool {
    for (str) |c| {
        if (!tok.isoneof(c, "0123456789")) return false;
    }
    return true;
}

pub fn single(comptime strf: fn ([]const u8) bool) SyntaxTreeNode.MatchFn {
    const Ret = struct {
        pub fn f(tokens: []const []const u8) SyntaxTreeNode.MatchFnRet {
            if (tokens.len == 0) return SyntaxTreeNode.MatchError.OutOfTokens;
            const token = tokens[0];

            if (strf(token)) {
                return 1;
            } else {
                return SyntaxTreeNode.MatchError.DoesNotMatch;
            }
        }
    };

    return Ret.f;
}
