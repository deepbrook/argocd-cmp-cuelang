package plugin

import (
	"tool/exec"
	"tool/os"
	"tool/cli"
	"encoding/json"
	"list"
	"strings"
	"github.com/deepbrook/argocd-cmp-cuelang/params"
)

env_vars: os.Getenv & {
	ARGOCD_APP_SOURCE_PATH: string
	ARGOCD_APP_PARAMETERS:  string | *"[]"
	ARGOCD_ENV_DEBUG:       string | *"false"
}

DEBUG: json.Unmarshal(env_vars.ARGOCD_ENV_DEBUG) & bool


// Validate the parameters ArgoCD has given us via ARGOCD_APP_PARAMETERS, populating default values where necessary
_given: json.Unmarshal(env_vars.ARGOCD_APP_PARAMETERS) & params.#UNMARSHALLED_ARGOCD_APP_PARAMS
given: params.Definitions & {for p in _given {(p.name): p & params.Definitions["\(p.name)"]}}


// Workflow to post 'dynamic' parameters - the output is used by ArgoCD to populate fields in the WebView of an Application.
command: "dynamic-params": {
	parameter_announcement: [for _, p in given {p}]
	out: cli.Print & {text: json.Marshal(parameter_announcement)}
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

	if given["cue-command"].string == "eval" {
		options: [
			if len(given.package.string) > 0 {given.package.string},
			"--out=\(given.output.string)",
			for e in given.expressions.array {"-e=\(e)"},
		]
	}
	if given["cue-command"].string == "cmd" {
		options: [given.workflow.string, if len(given.package.string) > 0 {given.package.string}]
	}

	cmd_list: list.Concat([
		["cue", given["cue-command"].string],
		options,
		[for t in given.tags.array {"-t=\(t)"}], // Always add -t/--inject parameters
	])

	debug: cli.Print & {text: strings.Join(["DEBUG: \(DEBUG):", strings.Join(cmd_list, " ")], " ")}

	proc: exec.Run & {
		$after: [debug]
		cmd: cmd_list
	}
}
