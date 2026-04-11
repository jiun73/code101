const std = @import("std");
const impl = @import("impl");
const SyntaxTreeNode = impl.SyntaxTreeNode;
const Context = impl.Context;
const fns = @import("fns.zig");
const llvm = @import("llvm");

pub const masterNode: SyntaxTreeNode = .{
    .debug = "master",
    .loopback = .Master,
    .next = &.{
        sectionNode,
    },
};

pub const variableRefNode = SyntaxTreeNode{
    .debug = "variableRef",
    .match = &.{fns.variableName},
    .build = Context.buildVariablePush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const resultNode = SyntaxTreeNode{
    .match = &.{
        fns.Eq("le").fun,
        fns.Eq("résultat").fun,
    },
    .build = Context.buildResultPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const copyNode = SyntaxTreeNode{
    .match = &.{
        fns.Eq("lui").fun,
        fns.Eq("-").fun,
        fns.Eq("même").fun,
    },
    .build = Context.buildCopyPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const constIntNode = SyntaxTreeNode{
    .match = &.{
        fns.integerValue,
    },
    .build = Context.buildConstPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const sqrtNode = SyntaxTreeNode{
    .match = &.{
        fns.Eq("la").fun,
        fns.Eq("racine").fun,
        fns.Eq("carrée").fun,
        fns.Eq("de").fun,
    },
    .build = &Context.pushOpFn(.SquareRoot),
    .next = &.{SyntaxTreeNode{ .loopback = .JumpPrevious }},
};

pub const expressionOpNode = SyntaxTreeNode{
    .loopback = .Self,
    .debug = "expression_op",
    .next = &.{
        .{
            .debug = "fois",
            .match = &.{fns.Eq("fois").fun},
            .next = &.{
                .{ .loopback = .JumpPrevious, .build = Context.pushOpFn(.Mul) },
            },
        },
        .{
            .debug = "fois",
            .match = &.{ fns.Eq("multiplié").fun, fns.Eq("par").fun },
            .next = &.{
                .{ .loopback = .JumpPrevious, .build = Context.pushOpFn(.Mul) },
            },
        },
        .{
            .debug = "plus",
            .match = &.{fns.Eq("plus").fun},
            .next = &.{
                .{ .loopback = .JumpPrevious, .build = Context.pushOpFn(.Add) },
            },
        },
        .{
            .debug = "square",
            .match = &.{ fns.Eq("au").fun, fns.Eq("carré").fun },
            .build = Context.pushOpFn(.Square),
            .next = &.{
                .{ .loopback = .Jump },
            },
        },
        .{
            .match = &.{fns.Eq(",").fun},
            .loopback = .Jump,
            .build = Context.resolveExpression,
        },
        .{
            .loopback = .Jump2Previous,
            .build = Context.endExpression,
        },
    },
};

pub const expressionNode = SyntaxTreeNode{
    .loopback = .Self,
    .debug = "expression",
    .next = &.{
        SyntaxTreeNode{
            .loopback = .After,
            .debug_after = "@expression_inner",
            .debug = "expression_inner",
            .next = &.{
                sqrtNode,
                resultNode,
                copyNode,
                constIntNode,
                variableRefNode,
            },
            .after = &.{expressionOpNode},
        },
    },
};

pub const enumerationNode = SyntaxTreeNode{
    .debug = "enum",
    .loopback = .Self,
    .next = &.{
        SyntaxTreeNode{
            .match = &.{
                fns.variableName,
                fns.Eq(",").fun,
            },
            .next = &.{
                SyntaxTreeNode{ .loopback = .Jump },
            },
        },
        SyntaxTreeNode{
            .match = &.{
                fns.variableName,
                fns.Eq("et").fun,
                fns.variableName,
            },
            .next = &.{
                SyntaxTreeNode{ .loopback = .JumpPrevious },
            },
        },
        SyntaxTreeNode{
            .match = &.{
                fns.variableName,
            },
            .next = &.{
                SyntaxTreeNode{ .loopback = .JumpPrevious },
            },
        },
    },
};

pub const phraseNode = SyntaxTreeNode{
    .debug = "phrase",
    .loopback = .Self,
    .next = &.{
        .{
            .debug = "phrase_2",
            .debug_after = "@phrase_2",
            .loopback = .After,
            .next = &.{
                SyntaxTreeNode{
                    .loopback = .JumpAfter,
                    .debug = "calculer",
                    .match = &.{
                        fns.Eq("calculer").fun,
                    },
                    .build_after = Context.endExpression,
                    .next = &.{
                        expressionNode,
                    },
                },
                SyntaxTreeNode{
                    .loopback = .After,
                    .debug = "mul",
                    .debug_after = "@mul",
                    .match = &.{
                        fns.Eq("multiplier").fun,
                    },
                    .next = &.{
                        variableRefNode,
                        expressionNode,
                    },
                    .after = &.{
                        SyntaxTreeNode{
                            .loopback = .JumpAfter,
                            .build_after = Context.buildMultiplyEq,
                            .match = &.{fns.Eq("par").fun},
                            .next = &.{expressionNode},
                        },
                        SyntaxTreeNode{
                            .loopback = .JumpAfter,
                            .build_after = Context.buildMultiply,
                            .match = &.{fns.Eq("avec").fun},
                            .next = &.{expressionNode},
                        },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("demander").fun,
                        fns.Eq("un").fun,
                        fns.Eq("nombre").fun,
                        fns.Eq("entier").fun,
                        fns.variableName,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("afficher").fun,
                        fns.Eq("le").fun,
                        fns.Eq("message").fun,
                        fns.stringValue,
                    },
                    .build = Context.buildPrintMessage,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("afficher").fun,
                        fns.Eq("le").fun,
                        fns.Eq("résultat").fun,
                    },
                    .build = Context.buildPrintResult,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .match = &.{
                        fns.Eq("afficher").fun,
                        fns.Eq("la").fun,
                        fns.Eq("valeur").fun,
                        fns.Eq("de").fun,
                        fns.variableName,
                    },
                    .build = Context.buildPrintVar,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                SyntaxTreeNode{
                    .debug = "declaration",
                    .debug_after = "@declaration",
                    .loopback = .After,
                    .match = &.{
                        fns.Eq("déclarer").fun,
                        fns.Eq("un").fun,
                        fns.Eq("nombre").fun,
                        fns.Eq("entier").fun,
                        fns.variableName,
                        fns.Eq("égal").fun,
                        fns.Eq("à").fun,
                    },
                    .tokens = .Save,
                    .next = &.{
                        expressionNode,
                    },
                    .after = &.{
                        SyntaxTreeNode{
                            .loopback = .Jump,
                            .tokens = .Saved,
                            .build = Context.buildDeclare,
                        },
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
                        fns.stringValue,
                    },
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
            },
            .after = &.{
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
                        fns.Eq(",").fun,
                        fns.Eq("puis").fun,
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
};

pub fn buildSectionFn(ctx: *Context, tokens: [][]const u8) !void {
    const fnName = tokens[2];

    if (std.mem.eql(u8, fnName, "principale")) {
        const fun = ctx.builder.module.addFn("main", .create(llvm.Type.Int32(), &.{ llvm.Type.Int32(), llvm.Type.Int8().Ptr().Ptr() }, false));
        const entry = fun.appendBasicBlock("entry");
        ctx.builder.ir.positionAtEnd(entry);
    } else {}
}

pub const sectionNode = SyntaxTreeNode{
    .debug = "section",
    .debug_after = "@section",
    .match = &.{
        fns.Eq("---").fun,
        fns.Eq("section").fun,
        fns.sectionLabel,
        fns.Eq("---").fun,
    },
    .build = buildSectionFn,
    .loopback = .After,
    .next = &.{
        phraseNode,
    },
    .after = &.{
        SyntaxTreeNode{
            .loopback = .End,
            .match = &.{
                fns.Eq("---").fun,
                fns.Eq("---").fun,
            },
            .build = Context.buildRet,
            .next = &.{SyntaxTreeNode{ .loopback = .Jump }},
        },
    },
};
