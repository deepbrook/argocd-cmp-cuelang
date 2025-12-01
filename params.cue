package params


// Parameter Definition Schemas
#ParameterDefinition: {
    title: string
    name: string
    tooltip: string
    required: bool | *false
    ...
}

#StringParameterDefinition: #ParameterDefinition & {
    collectionType: "string"
    "string": string | *""
}

#ArrayParameterDefinition: #ParameterDefinition & {
    collectionType: "array"
    "array": [...string] | *[]
}

// Parameter Validation Schemas
#ParameterValidation: {
    name!: string
    ...
}
#ArrayParameterValidation: #ParameterValidation & { "array": [...string] | *[] }
#StringParameterValidation: #ParameterValidation & { "string": string | *"" }


// Parameter Schema Obj
#Params: {
    cue_command: {
        id: "cue-command"
        default: "eval"
        def: #StringParameterDefinition & {
            title: "cue-cmd"
            name: id
            tooltip: "CUE sub-command to invoke (default: `\(default)`)"
            "string": default
        }
        val: #StringParameterValidation & {
            name: id
            "string": "eval" | "cmd" | *default
        }
    }

    package: {
        id: "package"

        def: #StringParameterDefinition & {
            title: "CUE Package"
            name: id
            tooltip: "CUE Package to run `cue` with."
        }
        val: #StringParameterValidation & {
            name: id
        }
    }

    tags: {
        id: "tags"
        def: #ArrayParameterDefinition & {
            title: "Injections"
            name: id
            tooltip: "list of key=value items to inject using the `-t` flag."
        }
        val: #ArrayParameterValidation & {
            name: id
        }
    }

    // `cue eval` only
    output: {
        id: "output"
        default: "yaml"
        def: #StringParameterDefinition & {
            title: "Format"
            name: id
            tooltip: "Output format to use when running `cue eval`. Restricted to JSON/YAML, as ArgoCD does not accept other formats."
            "string": default
        }
        val: #StringParameterValidation & {
            name: id
            "string": "json" | "yaml" | *default
        }
    }

    expressions: {
        id: "expressions"
        def: #ArrayParameterDefinition & {
            title: "Expressions"
            name: id
            tooltip: "Expressions to pass to `cue eval` via `-e/--expression` flag (default: none)."
        }
        val: #ArrayParameterValidation & {
            name: id
        }
    }

    // `cue cmd` only
    workflow: {
        id: "workflow"
        default: "build"

        def: #StringParameterDefinition & {
            title: "CUE Workflow Command"
            name: id
            tooltip: "Name of the workflow command defined in the `*_tool.cue` file called (default: `\(default)`). Ignored if `cue-command` is `eval`."
            required: true
            "string": default
        }
        val: #StringParameterValidation & {
            name: id
            "string": string | *default
        }
    }

    static: [cue_command.def, workflow.def, package.def, tags.def, expressions.def, output.def]
    dynamic: {for p in [cue_command.val, package.val, tags.val, output.val, expressions.val, workflow.val] {(p.name): p}}
}

help: #Params.static