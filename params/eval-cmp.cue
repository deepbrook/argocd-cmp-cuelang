package params

import "list"
import "strings"


#EvalParams: #CommonParams & {
    package: {
        id: "package"

        def: #StringParameterDefinition & {
            title: "CUE Package"
            name: id
            tooltip: "CUE Package to run `cue eval` with."
        }
        val: #StringParameterValidation & {
            name: id
        }
    }

    output: {
        id: "output"
        default: "yaml"
        def: #StringParameterDefinition & {
            title: "Format"
            name: id
            tooltip: "Output format to use when running `cue`. Restricted to JSON/YAML, as ArgoCD does not accept other formats."
            "string": default
        }
        val: #StringParameterValidation & {
            name: id
            "string": strings.ToLower(string | *default) & { "json" | "yaml"}
        }
    }

    expressions: {
        id: "expressions"
        def: #ArrayParameterDefinition & {
            title: "Expressions"
            name: id
            tooltip: "Expressions to pass to `cue eval` via '-e/--expression' flag (default: none)."
        }
        val: #ArrayParameterValidation & {
            name: id
        }
    }

    defaults: list.Concat([#CommonParams.defaults, [package.val, output.val, expressions.val]])
    static: list.Concat([#CommonParams.static, [package.def, output.def, expressions.def]])
}
