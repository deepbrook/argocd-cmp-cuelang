package cli

import "cue.dev/x/k8s.io/api/core/v1"

cm_data: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ConfigManagementPlugin"
	metadata: name: "cuelang"
	spec: {
		version: "v0.15.1"

		init: {
			command: ["cue"]
			args: ["version"]
		}

		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "github.com/deepbrook/argocd-cmp-cuelang"]
		}

		discover: {
			fileName: "./*.cue"
			find: {
				glob: "**/*.cue"
			}
		}

		parameters: {
			static: #Params.static
			dynamic: {
				command: ["cue", "cmd", "dynamic-params", "github.com/deepbrook/argocd-cmp-cuelang"]}
		}

		preserveFileMode: false
		provideGitCreds:  false
	}
}

cm: v1.#ConfigMap & {
	metadata: name: "argocd-cmp-cuelang"
	metadata: labels: {
		"app.kubernetes.io/component": "repo-server"
		"app.kubernetes.io/part-of":   "argocd"
	}
	data: "plugin.yaml": yaml.Marshal(cm_data)
}
