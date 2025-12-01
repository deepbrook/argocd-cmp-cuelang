package config

import "deepbrook.io/argocd-cmp-cuelang/params"


eval: #CmpConfigBase & {
	metadata: name: "cue-eval"
	spec: {
		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "deepbrook.io/argocd-cmp-cuelang/exec/eval"]
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
				command: ["cue", "cmd", "dynamic-params", "deepbrook.io/argocd-cmp-cuelang/exec/eval"]}
		}
	}
}