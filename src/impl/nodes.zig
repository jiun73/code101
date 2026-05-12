const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const Context = @import("Context.zig");
const fns = @import("fns.zig");
const zllvm = @import("zllvm");

//
// Ceci est le fichier principal qui définit la grammaire du langague
// Mon compilateur ne fait qu'une seul Pass et ne construit pas de AST
// C'est à dire qu'il lit simplement chaque token, en suivant l'arbre de syntaxe afin
// de savoir quel chemin emprunter, construisant le IR en chemin
//
// Voir la définition de SyntaxTreeNode pour savoir comment on fait pour traverser l'arbre
//

pub const master = SyntaxTreeNode{
    .debug = .label("master"),
    .branches = &.{
        &.{
            .loop(section),
            .any(),
        },
    },
};

const section = SyntaxTreeNode{
    .debug = .label("section"),
    .matching = .str("--- section [sectionlbl] ---"),
    .building = .get(Context.startFunctionDefinition, 2),
    .branches = &.{
        &.{
            .detour(section_prerequis),
            .detour(section_result),
            .build(.ctx(Context.buildFunction), .detour),
            .detour(section_step),
            .detour(paragraph),
            .next(.{}),
        },
        &.{
            .leaf(.{
                .matching = .str("--- ---"),
                .building = .ctx(Context.buildRet),
            }),
        },
    },
};

const section_step = SyntaxTreeNode{
    .branches = &.{
        &.{
            .next(
                .{
                    .matching = .str("Étape [step] :"),
                    .building = .get(Context.startStepBlock, 1),
                },
            ),
            .exit(),
        },
        &.{
            .prev(paragraph),
        },
    },
};

const paragraph = SyntaxTreeNode{
    .debug = .label("paragraph"),
    .branches = &.{
        &.{
            .detour(.{
                .branches = &.{
                    &.{
                        .leaf(.match("Tout d'abord ,")),
                    },
                },
            }),
            .next(phrase_full),
            .exit(),
        },
        &.{
            .detour(.{
                .branches = &.{
                    &.{
                        .leaf(.match("Ensuite ,")),
                        .leaf(.match("Après ,")),
                    },
                },
            }),
            .err(phrase_full, .loop),
            .exit(),
        },
    },
};

const phrase_full = SyntaxTreeNode{
    .debug = .label("phrase_full"),
    .branches = &.{
        &.{
            .err(phrase, .none),
            .leaf(phrase_if),
        },
    },
};

const phrase = SyntaxTreeNode{
    .debug = .label("phrase"),
    .branches = &.{
        &.{
            .next(phrase_nt),
        },
        &.{
            .leaf(.match(".")),
        },
    },
};

const phrase_nt = SyntaxTreeNode{
    .debug = .label("phrase_nt"),
    .branches = &.{
        &.{
            .leaf(expr_goto),
            .leaf(expr_restart),
            .next(expr_dire),
            .next(expr_dire_val),
            .next(expr_attendre),
            .next(expr_calculer),
            .next(expr_afficher_message),
            .next(expr_afficher_valeur),
            .next(expr_afficher),
            .next(expr_declarer),
            .next(expr_effectuer),
            .next(expr_eval_cond),
            .next(expr_demander),
        },
        &.{
            .prev(.match("et")),
            .prev(.match(", puis")),
            .any(),
        },
    },
};

const phrase_if = SyntaxTreeNode{
    .branches = &.{
        &.{.next(.match("si"))}, &.{.next(conditional)},
        &.{
            .build(.ctx(Context.buildCondition), .detour),
            .next(.match("alors")),
        },
        &.{.next(phrase_nt)},
        &.{
            .build(.ctx(Context.startElse), .detour),
            .next(.match(", sinon")),
        },
        &.{.next(phrase)},
        &.{
            .build(.ctx(Context.goNext), .none),
        },
    },
};

const expr_goto = SyntaxTreeNode{
    .matching = .str("aller à l'étape [step]"),
    .building = .get(Context.gotoStep, 3),
    .branches = &.{},
};

const expr_restart = SyntaxTreeNode{
    .matching = .str("recommencer l'étape"),
    .branches = &.{
        &.{.build(.ctx(Context.restartBlock), .none)},
    },
};

const expr_calculer = SyntaxTreeNode{
    .matching = .str("calculer"),
    .branches = &.{
        &.{.leaf(expression)},
    },
};

const expr_attendre = SyntaxTreeNode{
    .matching = .str("attendre [int]"),
    .building = .get(Context.buildSleep, 1),
    .branches = &.{
        &.{
            .leaf(.{
                .matching = .str("secondes"),
            }),
        },
    },
};

const expr_dire = SyntaxTreeNode{
    .matching = .str("dire [str]"),
    .building = .get(Context.buildTTSMessage, 1),
};

const expr_dire_val = SyntaxTreeNode{
    .matching = .str("dire la valeur de [var]"),
    .building = .get(Context.buildTTSMessage2, 4),
};

const expr_demander = SyntaxTreeNode{
    .matching = .str("demander un nombre réel [var]"),
    .building = .get(Context.buildAsk, 4),
};

const expr_afficher_message = SyntaxTreeNode{
    .matching = .str("afficher le message [str]"),
    .building = .get(Context.buildPrintMessage, 3),
};

const expr_afficher_valeur = SyntaxTreeNode{
    .matching = .str("afficher la valeur de [var]"),
    .building = .get(Context.buildPrintVar, 4),
};

const expr_eval_cond = SyntaxTreeNode{
    .debug = .label("eval"),
    .matching = .str("évaluer si"),
    //.buildFn = Context.buildDeclare,
    .branches = &.{
        &.{.leaf(conditional)},
    },
};

const expr_declarer = SyntaxTreeNode{
    .debug = .label("declare"),
    .matching = .str("déclarer un nombre entier [var] égal à"),
    .building = .get(Context.buildDeclare, 4),
    .branches = &.{
        &.{.next(expression)},
        &.{.build(.ctx(Context.endExpr), .none)},
    },
};

const expr_effectuer = SyntaxTreeNode{
    .matching = .str("effectuer les étapes de la section [str]"),
    .building = .get(Context.startBuildCall, 6),
    .branches = &.{
        &.{
            .detour(
                .{
                    .matching = .str("avec"),
                    .branches = &.{
                        &.{
                            .next(.{
                                .matching = .str("[var] égal à"),
                                .building = .get(Context.buildCallParams, 0),
                            }),
                        },
                        &.{
                            .next(expression),
                        },
                        &.{
                            .build(.ctx(Context.buildCallParamValue), .detour),
                            .restart(.match(",")),
                            .next(.match("et")),
                            .exit(),
                        },
                        &.{
                            .next(.{
                                .matching = .str("[var] égal à"),
                                .building = .get(Context.buildCallParams, 0),
                            }),
                        },
                        &.{
                            .next(expression),
                        },
                        &.{
                            .build(.ctx(Context.buildCallParamValue), .none),
                        },
                    },
                },
            ),
            .build(.ctx(Context.buildCall), .none),
        },
    },
};

const expr_afficher = SyntaxTreeNode{
    .matching = .str("afficher"),
    .branches = &.{
        &.{.next(expression)},
        &.{.build(.ctx(Context.buildPrintResult), .none)},
    },
};

const expression = SyntaxTreeNode{
    .debug = .label("expr"),
    .building = .ctx(Context.startExpr),
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
                .matching = .str(","),
                .building = .ctx(Context.restartExpr),
            }),
            .build(.ctx(Context.endExpr), .none),
        },
        &.{
            .restart(op_mul),
            .restart(op_mul2),
            .restart(op_add),
            .restart(op_add2),
            .restart(op_sub),
            .restart(op_div),
            .prev(op_square),
            .build(.ctx(Context.endExpr), .detour),
            .cancelDefer(),
        },
    },
};

const conditional = SyntaxTreeNode{
    .debug = .label("cond"),
    .building = .ctx(Context.startExpr),
    .branches = &.{
        &.{
            .err(expression, .{ .next = 0 }),
            .build(.ctx(Context.endExpr), .detour),
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
            .restart(.{ .deferConsume = true, .matching = .str("et"), .building = .ctx(Context.restartExpr) }),
            .restart(.{ .deferConsume = true, .matching = .str("ou"), .building = .ctx(Context.restartExpr) }),
            .build(.ctx(Context.endExpr), .none),
        },
    },
};

const op_mul = SyntaxTreeNode{
    .matching = .str("fois"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Multiply } })),
};

const op_mul2 = SyntaxTreeNode{
    .matching = .str("multiplié par"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Multiply } })),
};

const op_div = SyntaxTreeNode{
    .matching = .str("divisé par"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Divide } })),
};

const op_add = SyntaxTreeNode{
    .matching = .str("plus"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Add } })),
};

const op_add2 = SyntaxTreeNode{
    .matching = .str("additionné à"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Add } })),
};

const op_sub = SyntaxTreeNode{
    .matching = .str("moins"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Substract } })),
};

const op_square = SyntaxTreeNode{
    .matching = .str("au carré"),
    .building = .ctx(Context.doOpFn(.{ .arithmetic = .{ .unary = .Square } })),
};

const op_gt = SyntaxTreeNode{
    .matching = .str("est plus grand que"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .GreaterThan })),
};

const op_gte = SyntaxTreeNode{
    .matching = .str("est plus grand ou égal à"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .GreaterThanOrEqualTo })),
};

const op_lt = SyntaxTreeNode{
    .matching = .str("est plus petit que"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .LessThan })),
};

const op_lte = SyntaxTreeNode{
    .matching = .str("est plus petit ou égal à"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .LessThanOrEqualTo })),
};

const op_eq = SyntaxTreeNode{
    .matching = .str("est égal à"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .EqualTo })),
};

const op_neq = SyntaxTreeNode{
    .matching = .str("n'est pas égal à"),
    .building = .ctx(Context.pushOpFn(.{ .comparison = .NotEqualTo })),
};

const variableRef = SyntaxTreeNode{
    .matching = .str("[var]"),
    .building = .get(Context.buildVariablePush, 0),
};

const result = SyntaxTreeNode{
    .matching = .str("le résultat"),
    .building = .ctx(Context.buildResultPush),
};

pub const copyNode = SyntaxTreeNode{
    .matching = .str("lui - même"),
    .building = .ctx(Context.buildCopyPush),
};

pub const constIntNode = SyntaxTreeNode{
    .matching = .str("[int]"),
    .building = .get(Context.buildConstPush, 0),
};

pub const op_sqrt = SyntaxTreeNode{
    .matching = .str("la racine carrée de"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .unary = .SquareRoot } })),
};

pub const op_rem = SyntaxTreeNode{
    .matching = .str("le reste de la division de"),
    .building = .ctx(Context.pushOpFn(.{ .arithmetic = .{ .binary = .Remainder } })),
    .branches = &.{
        &.{
            .next(variableRef),
            .next(constIntNode),
            .next(result),
        },
        &.{
            .leaf(.{ .matching = .str("par") }),
        },
    },
};

pub const section_prerequis = SyntaxTreeNode{
    .debug = .label("param"),
    .matching = .str("Prérequis :"),
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
    .matching = .str("-"),
    .branches = &.{
        &.{
            .next(.{ .matching = .str("[var] ,"), .building = .get(Context.buildFunctionParam, 0) }),
        },
        &.{
            .next(type_real),
            .next(type_integer),
        },
        &.{
            .leaf(.{ .matching = .str(";"), .building = .ctx(Context.doOpFn(.{ .function_def = .PromoteToArgDef })) }),
        },
    },
};

pub const section_result = SyntaxTreeNode{
    .debug = .label("result"),
    .matching = .str("Résultat :"),
    .branches = &.{
        &.{.next(type_real)},
        &.{.leaf(.{ .matching = .str(".") })},
        //&.{.build(.ctx(Context.buildFunctionResult), .leaf)},
    },
};

pub const type_integer = SyntaxTreeNode{
    .debug = .label("int"),
    .building = .ctx(Context.pushType(.Int)),
    .matching = .str("un nombre entier"),
};

pub const type_real = SyntaxTreeNode{
    .debug = .label("real"),
    .building = .ctx(Context.pushType(.Real)),
    .matching = .str("un nombre réel"),
};
