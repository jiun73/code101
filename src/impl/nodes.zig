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
            .next(expr_eval_cond),
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

const expr_eval_cond = SyntaxTreeNode{
    .debug = .init("declare"),
    .matchFns = fns.eql("évaluer si"),
    //.buildFn = Context.buildDeclare,
    .branches = &.{
        &.{.leaf(conditional)},
    },
};

const expr_declarer = SyntaxTreeNode{
    .debug = .init("declare"),
    .matchFns = fns.eql("déclarer un nombre entier [var] égal à"),
    .buildFn = Context.buildDeclare,
    .branches = &.{
        &.{.next(expression)},
        &.{.buildLeaf(Context.endExpr)},
    },
};

const expr_effectuer = SyntaxTreeNode{
    .matchFns = fns.eql("effectuer les étapes de la section [str]"),
    .buildFn = Context.startBuildCall,
    .branches = &.{
        &.{
            .detour(
                .{
                    .matchFns = fns.eql("avec"),
                    .branches = &.{
                        &.{
                            .next(.{
                                .matchFns = fns.eql("[var] égal à"),
                                .buildFn = Context.buildCallParams,
                            }),
                        },
                        &.{
                            .next(expression),
                        },
                        &.{
                            .buildDetour(Context.buildCallParamValue),
                            .restart(.match(",")),
                            .next(.match("et")),
                            .exit(),
                        },
                        &.{
                            .next(.{
                                .matchFns = fns.eql("[var] égal à"),
                                .buildFn = Context.buildCallParams,
                            }),
                        },
                        &.{
                            .next(expression),
                        },
                        &.{
                            .buildLeaf(Context.buildCallParamValue),
                        },
                    },
                },
            ),
            .buildLeaf(Context.buildCall),
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
    .buildFn = Context.startExpr,
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
                .buildFn = Context.restartExpr,
            }),
            .buildLeaf(Context.endExpr),
        },
        &.{
            .restart(op_mul),
            .restart(op_mul2),
            .restart(op_add),
            .restart(op_add2),
            .restart(op_sub),
            .restart(op_div),
            .prev(op_square),
            .buildDetour(Context.endExpr),
            .cancelDefer(),
        },
    },
};

const conditional = SyntaxTreeNode{
    .debug = .init("cond"),
    .buildFn = Context.startExpr,
    .branches = &.{
        &.{
            .next(expression),
            .buildDetour(Context.endExpr),
            .cancelDefer(),
        },
        &.{
            .next(op_gt),
            .next(op_gte),
            .next(op_lt),
            .next(op_lte),
            .next(op_eq),
            .next(op_neq),
        },
        &.{
            .next(expression),
        },
        &.{
            .restart(.{ .deferConsume = true, .matchFns = fns.eql("et"), .buildFn = Context.restartExpr }),
            .restart(.{ .deferConsume = true, .matchFns = fns.eql("ou"), .buildFn = Context.restartExpr }),
            .buildLeaf(Context.endExpr),
        },
    },
};

const op_mul = SyntaxTreeNode{
    .matchFns = fns.eql("fois"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Multiply } }),
};

const op_mul2 = SyntaxTreeNode{
    .matchFns = fns.eql("multiplié par"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Multiply } }),
};

const op_div = SyntaxTreeNode{
    .matchFns = fns.eql("divisé par"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Divide } }),
};

const op_add = SyntaxTreeNode{
    .matchFns = fns.eql("plus"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Add } }),
};

const op_add2 = SyntaxTreeNode{
    .matchFns = fns.eql("additionné à"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Add } }),
};

const op_sub = SyntaxTreeNode{
    .matchFns = fns.eql("moins"),
    .buildFn = Context.pushOpFn(.{ .arithmetic = .{ .binary = .Substract } }),
};

const op_square = SyntaxTreeNode{
    .matchFns = fns.eql("au carré"),
    .buildFn = Context.doOpFn(.{ .arithmetic = .{ .unary = .Square } }),
};

const op_gt = SyntaxTreeNode{
    .matchFns = fns.eql("est plus grand que"),
    .buildFn = Context.pushOpFn(.{ .comparison = .GreaterThan }),
};

const op_gte = SyntaxTreeNode{
    .matchFns = fns.eql("est plus grand ou égal à"),
    .buildFn = Context.pushOpFn(.{ .comparison = .GreaterThanOrEqualTo }),
};

const op_lt = SyntaxTreeNode{
    .matchFns = fns.eql("est plus petit que"),
    .buildFn = Context.pushOpFn(.{ .comparison = .LessThan }),
};

const op_lte = SyntaxTreeNode{
    .matchFns = fns.eql("est plus petit ou égal à"),
    .buildFn = Context.pushOpFn(.{ .comparison = .LessThanOrEqualTo }),
};

const op_eq = SyntaxTreeNode{
    .matchFns = fns.eql("est égal à"),
    .buildFn = Context.pushOpFn(.{ .comparison = .EqualTo }),
};

const op_neq = SyntaxTreeNode{
    .matchFns = fns.eql("n'est pas égal à"),
    .buildFn = Context.pushOpFn(.{ .comparison = .NotEqualTo }),
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
    .buildFn = &Context.pushOpFn(.{ .arithmetic = .{ .unary = .SquareRoot } }),
};

pub const op_rem = SyntaxTreeNode{
    .matchFns = fns.eql("le reste de la division de"),
    .buildFn = &Context.pushOpFn(.{ .arithmetic = .{ .binary = .Remainder } }),
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
            .loop(section_param),
            .exit(),
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
