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
            .next(expr_afficher),
            .next(expr_declarer),
            .next(expr_effectuer),
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

const expr_effectuer = SyntaxTreeNode{
    .match = fns.eql("effectuer les étapes de la section [str]"),
    .build = Context.buildCall,
};

const expr_afficher = SyntaxTreeNode{
    .match = fns.eql("afficher"),
    .groups = &.{
        &.{.next(expression)},
        &.{.build(Context.buildPrintResult)},
    },
};

const expression = SyntaxTreeNode{
    .debug = .init("expr"),
    .groups = &.{
        &.{
            .loop(op_sqrt),
            .loop(op_rem),
            .next(variableRef),
            .next(constIntNode),
            .next(result),
        },
        &.{
            .prev(op_mul),
            .prev(op_mul2),
            .prev(op_add),
            .prev(op_add2),
            .prev(op_sub),
            .prev(op_div),
            .loop(op_square),
            .loop(.{
                .match = fns.eql(","),
                .build = Context.resolveExpression,
            }),
            .build(Context.endExpression),
        },
    },
};

const op_mul = SyntaxTreeNode{
    .match = fns.eql("fois"),
    .build = Context.pushOpFn(.Mul),
};

const op_mul2 = SyntaxTreeNode{
    .match = fns.eql("multiplié par"),
    .build = Context.pushOpFn(.Mul),
};

const op_div = SyntaxTreeNode{
    .match = fns.eql("divisé par"),
    .build = Context.pushOpFn(.Div),
};

const op_add = SyntaxTreeNode{
    .match = fns.eql("plus"),
    .build = Context.pushOpFn(.Add),
};

const op_add2 = SyntaxTreeNode{
    .match = fns.eql("additionné à"),
    .build = Context.pushOpFn(.Add),
};

const op_sub = SyntaxTreeNode{
    .match = fns.eql("moins"),
    .build = Context.pushOpFn(.Sub),
};

const op_square = SyntaxTreeNode{
    .match = fns.eql("au carré"),
    .build = Context.pushOpFn(.Square),
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

pub const op_sqrt = SyntaxTreeNode{
    .match = fns.eql("la racine carrée de"),
    .build = &Context.pushOpFn(.SquareRoot),
};

pub const op_rem = SyntaxTreeNode{
    .match = fns.eql("le reste de la division de"),
    .build = &Context.pushOpFn(.Rem),
    .groups = &.{
        &.{
            .next(variableRef),
            .next(constIntNode),
            .next(result),
        },
        &.{
            .init(.{
                .match = fns.eql("par"),
            }),
        },
    },
};
