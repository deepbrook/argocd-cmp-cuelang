package config

import (
	"encoding/yaml"
	"cue.dev/x/k8s.io/api/core/v1"
	"github.com/deepbrook/argocd-cmp-cuelang/params"
	"github.com/deepbrook/argocd-cmp-cuelang:plugin"
)

cm_data: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ConfigManagementPlugin"
	metadata: name: "cuelang"
	spec: {
		version: plugin.version

		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "github.com/deepbrook/argocd-cmp-cuelang@\(plugin.version):plugin"]
		}

		discover: {
			fileName: "./*.cue"
			find: {
				glob: "**/*.cue"
			}
		}

		parameters: {
			static: [for p, schema in params.Definitions {schema}]
			dynamic: {
				command: ["cue", "cmd", "dynamic-params", "github.com/deepbrook/argocd-cmp-cuelang@\(plugin.version):plugin"]}
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
