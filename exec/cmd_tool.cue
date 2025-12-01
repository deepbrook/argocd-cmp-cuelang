package cmd

import "deepbrook.io/argocd-cmp-cuelang/params"
import "tool/exec"
import "tool/os"
import "tool/cli"
import "encoding/json"
import "list"
import "strings"

env_vars: os.Getenv & {
    ARGOCD_APP_PARAMETERS: string
    DEBUG: string | *"false"
}

DEBUG: json.Unmarshal(env_vars.DEBUG) & bool

param_list: json.Unmarshal(env_vars.ARGOCD_APP_PARAMETERS)

parameters: { for p in params.#CmdParams.defaults {(p.name): p} } & {for p in param_list {(p.name): p}}

command: announce: {
    out: cli.Print & { text: json.Marshal(parameters) }
}

command: generate: {

    cmd_list: list.Concat([
        ["cue", "cmd", parameters.workflow.string, parameters.tool.string],
        [for t in parameters.tags.array {"-t=\(t)"}],
    ])

    if DEBUG {
        debug: cli.Print & {text: strings.Join(["DEBUG: \(DEBUG):", strings.Join(cmd_list, " ")], " ")}
    }

    proc: exec.Run & {cmd: cmd_list}
}

