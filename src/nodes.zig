const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");
const AST = @import("ast.zig");

pub const masterNode: SyntaxTreeNode = .{
    .debug = "master",
    .loopback = .Master,
    .next = &.{
        sectionNode,
    },
};

pub const phraseNode = SyntaxTreeNode{
    .debug = "phrase",
    .loopback = .Self,
    .next = &.{
        SyntaxTreeNode{
            .debug = "phrase_2",
            .loopback = .Next,
            .next = &.{
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("demander").fun,
                        fns.Eq("un").fun,
                        fns.Eq("nombre").fun,
                        fns.Eq("entier").fun,
                        fns.variable,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("afficher").fun,
                        fns.variable,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("déclarer").fun,
                        fns.Eq("un").fun,
                        fns.Eq("nombre").fun,
                        fns.Eq("entier").fun,
                        fns.variable,
                        fns.Eq("égal").fun,
                        fns.Eq("à").fun,
                        fns.Eq("1").fun,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("effectuer").fun,
                        fns.Eq("les").fun,
                        fns.Eq("étapes").fun,
                        fns.Eq("de").fun,
                        fns.Eq("la").fun,
                        fns.Eq("section").fun,
                        fns.string,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
            },
            .lbnext = &SyntaxTreeNode{
                .debug = "phrase_after",
                .next = &.{
                    SyntaxTreeNode{
                        .match = &.{
                            fns.Eq("et").fun,
                        },
                        .next = &.{
                            SyntaxTreeNode{ .debug = "loop", .loopback = .Jump },
                        },
                    },
                    SyntaxTreeNode{
                        .match = &.{
                            fns.Eq(".").fun,
                        },
                        .next = &.{
                            SyntaxTreeNode{ .debug = "phrase_end", .loopback = .JumpPrevious },
                        },
                    },
                },
            },
        },
    },
};

pub fn buildSectionFn(_: AST.Builder, _: [][]const u8) void {
    std.debug.print("build section fn\n", .{});
}

pub const sectionNode = SyntaxTreeNode{
    .debug = "section",
    .match = &.{
        fns.Eq("---").fun,
        fns.Eq("section").fun,
        fns.sectionLabel,
        fns.Eq("---").fun,
    },
    .build = buildSectionFn,
    .loopback = .Next,
    .next = &.{
        phraseNode,
    },
    .lbnext = &SyntaxTreeNode{
        .debug = "section_end",
        .next = &.{
            SyntaxTreeNode{
                .loopback = .End,
                .match = &.{
                    fns.Eq("---").fun,
                    fns.Eq("---").fun,
                },
                .next = &.{SyntaxTreeNode{ .loopback = .Jump }},
            },
        },
    },
};
