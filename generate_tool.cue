package plugin

import (
	"tool/exec"
	"tool/os"
	"tool/cli"
	"encoding/json"
	"list"
	"strings"
)

env_vars: os.Getenv & {
	ARGOCD_APP_SOURCE_PATH: string
	ARGOCD_APP_PARAMETERS:  string | *"[]"
	ARGOCD_ENV_DEBUG:       string | *"false"
}

DEBUG: json.Unmarshal(env_vars.ARGOCD_ENV_DEBUG) & bool


// Validate the parameters ArgoCD has given us via ARGOCD_APP_PARAMETERS, populating default values where necessary
given: json.Unmarshal(env_vars.ARGOCD_APP_PARAMETERS) & #UNMARSHALLED_ARGOCD_APP_PARAMS
parameters: #Params & {for p in given {(p.name): p & #Params["\(p.name)"]}}


// Workflow to post 'dynamic' parameters - the output is used by ArgoCD to populate fields in the WebView of an Application.
command: "dynamic-params": {
	out: cli.Print & {text: json.Marshal(parameters)}
}

// Execute a `cue` sub-command with the given CLI options.
//
// Supported sub-commands are `eval` and `cmd`; depending
// on the value of `parameters.cue_commmand`, the following
// parameters are honored:
//
// - cue-command: `eval`
//   Supported parameters: `output`, `expressions`
//
// - cue-command: `cmd`
//   Supported parameters: `workflow`
//
// The parameters supported by the sub-command **not** specified in `cue-command` are **ignored**.
//
// The parameter `package` (if a non-empty string) and `tags`
// are always honored.
command: generate: {

	options: [...string] | *[]
	if parameters["cue-command"].string == "eval" {
		options: [
			if len(parameters.package.string) > 0 {parameters.package.string},
			"--out=\(parameters.output.string)",
			for e in parameters.expressions.array {"-e=\(e)"},
		]
	}
	if parameters["cue-command"].string == "cmd" {
		options: [parameters.workflow.string, if len(parameters.package.string) > 0 {parameters.package.string}]
	}

	cmd_list: list.Concat([
		["cue", parameters["cue-command"].string],
		options,
		[for t in parameters.tags.array {"-t=\(t)"}], // Always add -t/--inject parameters
	])

	if DEBUG {
		debug: cli.Print & {text: strings.Join(["DEBUG: \(DEBUG):", strings.Join(cmd_list, " ")], " ")}
	}

	proc: exec.Run & {
		cmd: cmd_list
		dir: env_vars.ARGOCD_APP_SOURCE_PATH
	}
}
