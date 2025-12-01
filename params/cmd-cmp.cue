package params

import "list"

#CmdParams: #CommonParams & {
    tool: {
        id: "tool"

        def: #StringParameterDefinition & {
            title: "CUE Workflow Path"
            name: id
            tooltip: "Path to a '*_tool.cue' file or to a CUE package containing one. (default: directory)"
        }
        val: #StringParameterValidation & {
            name: id
        }
    }

    workflow: {
        id: "workflow"
        default: "build"

        def: #StringParameterDefinition & {
            title: "CUE Workflow Command"
            name: id
            tooltip: "Name of the workflow command defined in the `*_tool.cue` file called (default: `\(default)`)."
            required: true
            "string": default
        }
        val: #StringParameterValidation & {
            name: id
            value: string | *default
        }
    }

    defaults: list.Concat([#CommonParams.defaults, [tool.val, workflow.val]])
    static: list.Concat([#CommonParams.static, [tool.def, workflow.def]])
}
