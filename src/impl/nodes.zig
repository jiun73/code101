const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const Context = @import("Context.zig");
const fns = @import("fns.zig");
const llvm = @import("llvm");

pub const masterNode: SyntaxTreeNode = .{
    .debug = .init("master"),
    .loopback = .Master,
    .next = &.{
        sectionNode,
    },
};

pub const variableRefNode = SyntaxTreeNode{
    .debug = .init("variableRef"),
    .match = &.{fns.single(fns.variableName)},
    .build = Context.buildVariablePush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const resultNode = SyntaxTreeNode{
    .match = fns.eql("le résultat"),
    .build = Context.buildResultPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const copyNode = SyntaxTreeNode{
    .match = fns.eql("lui - même"),
    .build = Context.buildCopyPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const constIntNode = SyntaxTreeNode{
    .match = &.{
        fns.single(fns.integerValue),
    },
    .build = Context.buildConstPush,
    .next = &.{
        SyntaxTreeNode{ .loopback = .Jump },
    },
};

pub const sqrtNode = SyntaxTreeNode{
    .match = fns.eql("la racine carrée de"),
    .build = &Context.pushOpFn(.SquareRoot),
    .next = &.{SyntaxTreeNode{ .loopback = .JumpPrevious }},
};

pub const remNode = SyntaxTreeNode{
    .match = fns.eql("le reste de la division de"),
    .build = &Context.pushOpFn(.SquareRoot),
    .next = &.{SyntaxTreeNode{ .loopback = .JumpPrevious }},
};

pub const expressionOpNode = SyntaxTreeNode{
    .loopback = .Self,
    .debug = .init("expression_op"),
    .next = &.{
        .{
            .debug = .init("fois"),
            .match = fns.eql("fois"),
            .build = Context.pushOpFn(.Mul),
            .next = &.{
                .{ .loopback = .JumpPrevious },
            },
        },
        .{
            .debug = .init("fois"),
            .match = fns.eql("multiplié par"),
            .build = Context.pushOpFn(.Mul),
            .next = &.{
                .{ .loopback = .JumpPrevious },
            },
        },
        .{
            .debug = .init("divisé par"),
            .match = fns.eql("divisé par"),
            .build = Context.pushOpFn(.Mul),
            .next = &.{
                .{ .loopback = .JumpPrevious },
            },
        },
        .{
            .debug = .init("plus"),
            .match = fns.eql("plus"),
            .build = Context.pushOpFn(.Add),
            .next = &.{
                .{ .loopback = .JumpPrevious },
            },
        },
        .{
            .debug = .init("moins"),
            .match = fns.eql("moins"),
            .build = Context.pushOpFn(.Sub),
            .next = &.{
                .{ .loopback = .JumpPrevious },
            },
        },
        .{
            .debug = .init("square"),
            .match = fns.eql("au carré"),
            .build = Context.pushOpFn(.Square),
            .next = &.{
                .{ .loopback = .Jump },
            },
        },
        .{
            .match = fns.eql(","),
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
    .debug = .init("expression"),
    .next = &.{
        SyntaxTreeNode{
            .loopback = .After,
            .debug = .init("expression_inner"),
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
    .debug = .init("phrase"),
    .loopback = .Self,
    .next = &.{
        .{
            .debug = .init("phrase_2"),
            .loopback = .After,
            .next = &.{
                .{
                    .loopback = .JumpAfter,
                    .debug = .init("calculer"),
                    .match = fns.eql("calculer"),
                    //.build_after = Context.endExpression,
                    .next = &.{
                        expressionNode,
                    },
                },
                .{
                    .loopback = .After,
                    .debug = .init("mul"),
                    .match = fns.eql("multiplier"),
                    .next = &.{
                        variableRefNode,
                        expressionNode,
                    },
                    .after = &.{
                        SyntaxTreeNode{
                            .loopback = .JumpAfter,
                            .build_after = Context.buildMultiplyEq,
                            .match = fns.eql("par"),
                            .next = &.{expressionNode},
                        },
                        SyntaxTreeNode{
                            .loopback = .JumpAfter,
                            .build_after = Context.buildMultiply,
                            .match = fns.eql("avec"),
                            .next = &.{expressionNode},
                        },
                    },
                },
                .{
                    .match = fns.eql("demander un nombre entier") ++ .{fns.single(fns.variableName)},
                    .next = SyntaxTreeNode.jumpl,
                },
                .{
                    .match = fns.eql("afficher le message") ++ .{fns.single(fns.stringValue)},
                    .build = Context.buildPrintMessage,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                .{
                    .match = fns.eql("afficher le résultat"),
                    .build = Context.buildPrintResult,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                .{
                    .match = fns.eql("afficher la valeur de") ++ .{fns.single(fns.variableName)},
                    .build = Context.buildPrintVar,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
                .{
                    .loopback = .JumpAfter,
                    .match = fns.eql("afficher"),
                    .build_after = Context.buildPrintResult,
                    .next = &.{
                        expressionNode,
                    },
                    .after = &.{SyntaxTreeNode{ .loopback = .Jump }},
                },
                SyntaxTreeNode{
                    .debug = .init("declaration"),
                    .loopback = .After,
                    .match = fns.eql("déclarer un nombre entier") ++ .{fns.single(fns.variableName)} ++ fns.eql("égal à"),
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
                    .match = fns.eql("effectuer les étapes de la section") ++ .{fns.single(fns.stringValue)},
                    .build = Context.buildCall,
                    .next = &.{
                        SyntaxTreeNode{ .loopback = .Jump },
                    },
                },
            },
            .after = &.{
                .{
                    .match = fns.eql("et"),
                    .next = &.{
                        SyntaxTreeNode{ .debug = .init("loop"), .loopback = .Jump },
                    },
                },
                .{
                    .match = fns.eql(", puis"),
                    .next = &.{
                        SyntaxTreeNode{ .debug = .init("loop"), .loopback = .Jump },
                    },
                },
                .{
                    .match = fns.eql("."),
                    .next = &.{
                        SyntaxTreeNode{ .debug = .init("phrase_end"), .loopback = .JumpPrevious },
                    },
                },
            },
        },
    },
};

pub const sectionNode = SyntaxTreeNode{
    .match = fns.eql("--- section") ++ .{fns.single(fns.sectionLabel)} ++ fns.eql("---"),
    .build = Context.buildSection,
    .loopback = .After,
    .next = &.{
        phraseNode,
    },
    .after = &.{
        SyntaxTreeNode{
            .loopback = .End,
            .match = fns.eql("--- ---"),
            .build = Context.buildRet,
            .next = &.{SyntaxTreeNode{ .loopback = .Jump }},
        },
    },
};
