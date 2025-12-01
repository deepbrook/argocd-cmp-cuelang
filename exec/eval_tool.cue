package eval

import "github.com/deepbrook/argocd-cmp-cuelang/params"

import "tool/exec"

import "tool/os"

import "tool/cli"

import "encoding/json"

import "list"

import "strings"

env_vars: os.Getenv & {
	ARGOCD_APP_PARAMETERS: string
	DEBUG:                 string | *"false"
}

DEBUG: json.Unmarshal(env_vars.DEBUG) & bool

param_list: json.Unmarshal(env_vars.ARGOCD_APP_PARAMETERS)

parameters: {for p in params.#EvalParams.defaults {(p.name): p}} & {for p in param_list {(p.name): p}}

command: announce: {
	out: cli.Print & {text: json.Marshal(parameters)}
}

command: generate: {

	cmd_list: list.Concat([
		["cue", "eval", "--out", parameters.output.string],
		if len(parameters.package.string) > 0 {[parameters.package.string]},
		[for e in parameters.expressions.array {"-e=\(e)"}],
		[for t in parameters.tags.array {"-t=\(t)"}],
	])

	if DEBUG {
		debug: cli.Print & {text: strings.Join(["DEBUG: \(DEBUG):", strings.Join(cmd_list, " ")], " ")}
	}
	proc: exec.Run & {cmd: cmd_list}
}
