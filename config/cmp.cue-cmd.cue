package config

import "github.com/deepbrook/argocd-cmp-cuelang/params"

cmd: #CmpConfigBase & {
	metadata: name: "cue-cmd"
	spec: {
		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "github.com/deepbrook/argocd-cmp-cuelang/exec/cmd"]
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
				command: ["cue", "cmd", "dynamic-params", "github.com/deepbrook/argocd-cmp-cuelang/exec/cmd"]}
		}
	}
}
