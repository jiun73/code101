const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const Context = @import("Context.zig");
const fns = @import("fns.zig");
const llvm = @import("llvm");

pub const master = SyntaxTreeNode{
    .debug = .init("master"),
    .groups = &.{
        &.{
            .loop(section),
            .end(),
        },
    },
};

const section = SyntaxTreeNode{
    .debug = .init("section"),
    .match = fns.eql("--- section [sectionlbl] ---"),
    .build = Context.buildSection,
    .groups = &.{
        &.{.next(phrase)},
        &.{
            .init(.{
                .match = fns.eql("--- ---"),
                .build = Context.buildRet,
            }),
        },
    },
};

const phrase = SyntaxTreeNode{
    .groups = &.{
        &.{
            .next(expr_calculer),
            .next(expr_afficher_message),
            .next(expr_afficher_valeur),
            .next(expr_declarer),
        },
        &.{
            .init(.{ .match = fns.eql(".") }),
            .prev(.{ .match = fns.eql("et") }),
        },
    },
};

const expr_calculer = SyntaxTreeNode{
    .match = fns.eql("calculer"),
    .groups = &.{
        &.{.init(expression)},
    },
};

const expr_afficher_message = SyntaxTreeNode{
    .match = fns.eql("afficher le message [str]"),
    .build = Context.buildPrintMessage,
};

const expr_afficher_valeur = SyntaxTreeNode{
    .match = fns.eql("afficher la valeur de [var]"),
    .build = Context.buildPrintVar,
};

const expr_declarer = SyntaxTreeNode{
    .match = fns.eql("déclarer un nombre entier [var] égal à"),
    .build = Context.buildDeclare,
    .groups = &.{
        &.{.next(expression)},
        &.{.build(Context.resolveExpression)},
    },
};

const expression = SyntaxTreeNode{
    .debug = .init("expr"),
    .groups = &.{
        &.{
            .next(constIntNode),
        },
        &.{
            .any(),
        },
    },
};

const variableRef = SyntaxTreeNode{
    .match = fns.eql("[var]"),
    .build = Context.buildVariablePush,
};

const result = SyntaxTreeNode{
    .match = fns.eql("le résultat"),
    .build = Context.buildResultPush,
};

pub const copyNode = SyntaxTreeNode{
    .match = fns.eql("lui - même"),
    .build = Context.buildCopyPush,
};

pub const constIntNode = SyntaxTreeNode{
    .match = fns.eql("[int]"),
    .build = Context.buildConstPush,
};

pub const sqrtNode = SyntaxTreeNode{
    .match = fns.eql("la racine carrée de"),
    .build = &Context.pushOpFn(.SquareRoot),
};

pub const remNode = SyntaxTreeNode{
    .match = fns.eql("le reste de la division de"),
    .build = &Context.pushOpFn(.SquareRoot),
};
