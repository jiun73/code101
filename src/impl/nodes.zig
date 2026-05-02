const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const Context = @import("Context.zig");
const fns = @import("fns.zig");
const llvm = @import("llvm");

pub const master = SyntaxTreeNode{
    .debug = .init("master"),
    .branches = &.{
        &.{
            .loop(section),
            .end(),
        },
    },
};

const section = SyntaxTreeNode{
    .debug = .init("section"),
    .matchFns = fns.eql("--- section [sectionlbl] ---"),
    .buildFn = Context.startFunctionDefinition,
    .branches = &.{
        &.{
            .detour(section_prerequis),
            .detour(section_result),
            .detour(.{ .buildFn = Context.buildFunction }),
            .next(phrase),
        },
        &.{
            .leaf(.{
                .matchFns = fns.eql("--- ---"),
                .buildFn = Context.buildRet,
            }),
        },
    },
};

const phrase = SyntaxTreeNode{
    .branches = &.{
        &.{
            .next(expr_dire),
            .next(expr_attendre),
            .next(expr_calculer),
            .next(expr_afficher_message),
            .next(expr_afficher_valeur),
            .next(expr_afficher),
            .next(expr_declarer),
            .next(expr_effectuer),
        },
        &.{
            .leaf(.{ .matchFns = fns.eql(".") }),
            .prev(.{ .matchFns = fns.eql("et") }),
            .prev(.{ .matchFns = fns.eql(", puis") }),
        },
    },
};

const expr_calculer = SyntaxTreeNode{
    .matchFns = fns.eql("calculer"),
    .branches = &.{
        &.{.leaf(expression)},
    },
};

const expr_attendre = SyntaxTreeNode{
    .matchFns = fns.eql("attendre [int]"),
    .buildFn = Context.buildSleep,
    .branches = &.{
        &.{
            .leaf(.{
                .matchFns = fns.eql("secondes"),
            }),
        },
    },
};

const expr_dire = SyntaxTreeNode{
    .matchFns = fns.eql("dire [str]"),
    .buildFn = Context.buildTTSMessage,
};

const expr_afficher_message = SyntaxTreeNode{
    .matchFns = fns.eql("afficher le message [str]"),
    .buildFn = Context.buildPrintMessage,
};

const expr_afficher_valeur = SyntaxTreeNode{
    .matchFns = fns.eql("afficher la valeur de [var]"),
    .buildFn = Context.buildPrintVar,
};

const expr_declarer = SyntaxTreeNode{
    .debug = .init("declare"),
    .matchFns = fns.eql("déclarer un nombre entier [var] égal à"),
    .buildFn = Context.buildDeclare,
    .branches = &.{
        &.{.leaf(expression)},
    },
};

const expr_effectuer = SyntaxTreeNode{
    .matchFns = fns.eql("effectuer les étapes de la section [str]"),
    .buildFn = Context.buildCall,
    .branches = &.{
        &.{
            .leaf(
                .{
                    .matchFns = fns.eql("avec"),
                    .branches = &.{
                        &.{
                            .next(.match("[var] égal à")),
                        },
                        &.{
                            .next(expression),
                        },
                        &.{
                            .restart(.match(",")),
                            .next(.match("et")),
                            .leafAny(),
                        },
                        &.{
                            .next(.match("[var] égal à")),
                        },
                        &.{
                            .leaf(expression),
                        },
                    },
                },
            ),
            .leafAny(),
        },
    },
};

const expr_afficher = SyntaxTreeNode{
    .matchFns = fns.eql("afficher"),
    .branches = &.{
        &.{.next(expression)},
        &.{.buildLeaf(Context.buildPrintResult)},
    },
};

const expression = SyntaxTreeNode{
    .debug = .init("expr"),
    .branches = &.{
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
            .next(.{
                .deferConsume = true,
                .matchFns = fns.eql(","),
                .buildFn = Context.resolveExpression,
            }),
            .buildLeaf(Context.endExpression),
        },
        &.{
            .restart(op_mul),
            .restart(op_mul2),
            .restart(op_add),
            .restart(op_add2),
            .restart(op_sub),
            .restart(op_div),
            .prev(op_square),
            .buildDetour(Context.endExpression),
            .cancelDefer(),
        },
    },
};

const op_mul = SyntaxTreeNode{
    .matchFns = fns.eql("fois"),
    .buildFn = Context.pushOpFn(.Mul),
};

const op_mul2 = SyntaxTreeNode{
    .matchFns = fns.eql("multiplié par"),
    .buildFn = Context.pushOpFn(.Mul),
};

const op_div = SyntaxTreeNode{
    .matchFns = fns.eql("divisé par"),
    .buildFn = Context.pushOpFn(.Div),
};

const op_add = SyntaxTreeNode{
    .matchFns = fns.eql("plus"),
    .buildFn = Context.pushOpFn(.Add),
};

const op_add2 = SyntaxTreeNode{
    .matchFns = fns.eql("additionné à"),
    .buildFn = Context.pushOpFn(.Add),
};

const op_sub = SyntaxTreeNode{
    .matchFns = fns.eql("moins"),
    .buildFn = Context.pushOpFn(.Sub),
};

const op_square = SyntaxTreeNode{
    .matchFns = fns.eql("au carré"),
    .buildFn = Context.pushOpFn(.Square),
};

const variableRef = SyntaxTreeNode{
    .matchFns = fns.eql("[var]"),
    .buildFn = Context.buildVariablePush,
};

const result = SyntaxTreeNode{
    .matchFns = fns.eql("le résultat"),
    .buildFn = Context.buildResultPush,
};

pub const copyNode = SyntaxTreeNode{
    .matchFns = fns.eql("lui - même"),
    .buildFn = Context.buildCopyPush,
};

pub const constIntNode = SyntaxTreeNode{
    .matchFns = fns.eql("[int]"),
    .buildFn = Context.buildConstPush,
};

pub const op_sqrt = SyntaxTreeNode{
    .matchFns = fns.eql("la racine carrée de"),
    .buildFn = &Context.pushOpFn(.SquareRoot),
};

pub const op_rem = SyntaxTreeNode{
    .matchFns = fns.eql("le reste de la division de"),
    .buildFn = &Context.pushOpFn(.Rem),
    .branches = &.{
        &.{
            .next(variableRef),
            .next(constIntNode),
            .next(result),
        },
        &.{
            .leaf(.{ .matchFns = fns.eql("par") }),
        },
    },
};

pub const section_prerequis = SyntaxTreeNode{
    .debug = .init("param"),
    .matchFns = fns.eql("Prérequis :"),
    .branches = &.{
        &.{
            .next(section_param),
        },
        &.{
            .loopOrError(section_param, .next),
            .leafAny(),
        },
    },
};

pub const section_param = SyntaxTreeNode{
    .matchFns = fns.eql("-"),
    .branches = &.{
        &.{
            .next(.{ .matchFns = fns.eql("[var] ,"), .buildFn = Context.buildFunctionParam }),
        },
        &.{
            .next(type_real),
            .next(type_integer),
        },
        &.{
            .leaf(.{ .matchFns = fns.eql(";") }),
        },
    },
};

pub const section_result = SyntaxTreeNode{
    .debug = .init("result"),
    .matchFns = fns.eql("Résultat :"),
    .branches = &.{
        &.{.next(type_real)},
        &.{.next(.{ .matchFns = fns.eql(".") })},
        &.{.buildLeaf(Context.buildFunctionResult)},
    },
};

pub const type_integer = SyntaxTreeNode{
    .debug = .init("int"),
    .buildFn = Context.pushType(.Int),
    .matchFns = fns.eql("un nombre entier"),
};

pub const type_real = SyntaxTreeNode{
    .debug = .init("real"),
    .buildFn = Context.pushType(.Real),
    .matchFns = fns.eql("un nombre réel"),
};
