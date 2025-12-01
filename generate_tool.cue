package exec

import (
    "github.com/deepbrook/argocd-cmp-cuelang:params"
    "tool/exec"
    "tool/os"
    "tool/cli"
    "encoding/json"
    "list"
    "strings"
)

env_vars: os.Getenv & {
	ARGOCD_APP_SOURCE_PATH: string
	ARGOCD_APP_PARAMETERS: string
	DEBUG:                 string | *"false"
}

DEBUG: json.Unmarshal(env_vars.DEBUG) & bool

// Validate the parameters ArgoCD has given us via ARGOCD_APP_PARAMETERS, filling default values where necessary
parameters: params.#Params.dynamic & {for p in json.Unmarshal(env_vars.ARGOCD_APP_PARAMETERS) {(p.name): p}}

// Workflow to post 'dynamic' parameters - the output is used by ArgoCD to populate fields in the WebView of an Application.
command: "dynamic-params": {
	out: cli.Print & {text: json.Marshal(parameters)}
}

// Workflow to generate k8s manifests using the respective cue sub-command (eval or cmd).
command: generate: {

	cmd_list: list.Concat([
		["cue", parameters.cue_command.string],
		if parameters.cue_command.string == "eval" {[parameters.workflow.string]},
		if len(parameters.package.string) > 0 {[parameters.package.string]},
        if parameters.cue_command.string == "eval" {["--out", parameters.output.string]},
		if parameters.cue_command.string == "eval" {[for e in parameters.expressions.array {"-e=\(e)"}]},
		[for t in parameters.tags.array {"-t=\(t)"}],
	])

	if DEBUG {
		debug: cli.Print & {text: strings.Join(["DEBUG: \(DEBUG):", strings.Join(cmd_list, " ")], " ")}
	}
	proc: exec.Run & {
		cmd: cmd_list
		dir: env_vars.ARGOCD_APP_SOURCE_PATH
	}
}
