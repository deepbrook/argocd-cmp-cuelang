package config

import "deepbrook.io/argocd-cmp-cuelang/params"


cmd: #CmpConfigBase & {
	metadata: name: "cue-cmd"
	spec: {
		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "deepbrook.io/argocd-cmp-cuelang/exec/cmd"]
		}

		discover: {
			fileName: "./*_tool.cue"
			find: {
				glob: "**/*_tool.cue"
			}
		}

		parameters: {
			static: params.#CmdParams.static
			dynamic: {
				command: ["cue", "cmd", "dynamic-params", "deepbrook.io/argocd-cmp-cuelang/exec/cmd"]}
		}
	}
}