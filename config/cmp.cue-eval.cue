package config

import "github.com/deepbrook/argocd-cmp-cuelang/params"

eval: #CmpConfigBase & {
	metadata: name: "cue-eval"
	spec: {
		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "github.com/deepbrook/argocd-cmp-cuelang/exec/eval"]
		}

		discover: {
			fileName: "./*.cue"
			find: {
				glob: "**/*.cue"
			}
		}

		parameters: {
			static: params.#CmdParams.static
			dynamic: {
				command: ["cue", "cmd", "dynamic-params", "github.com/deepbrook/argocd-cmp-cuelang/exec/eval"]}
		}
	}
}
