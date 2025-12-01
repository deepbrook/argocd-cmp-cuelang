package setup

import (
	"github.com/deepbrook/argocd-cmp-cuelang:params"
)

cm: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ConfigManagementPlugin"
	metadata: name: "cuelang"
	spec: {
		version: "v0.15.1"

		init: {
			command: ["sh"]
			args: ["-c", "echo", "Initializing.."]
		}

		generate: {
			command: ["cue"]
			args: ["cmd", "generate", "github.com/deepbrook/argocd-cmp-cuelang:exec"]
		}

		discover: {
			fileName: "./*.cue"
			find: {
				glob: "**/*.cue"
			}
		}

		parameters: {
			static: params.#Params.static
			dynamic: {
				command: ["cue", "cmd", "dynamic-params", "github.com/deepbrook/argocd-cmp-cuelang:exec"]}
		}

		preserveFileMode: false
		provideGitCreds: false
	}
}



patch: spec: template: spec: containers: [{
    name: "cuelang"
    command: ["/var/run/argocd/argocd-cmp-server", "--loglevel=info"]
    image: "cuelang/cue"
    securityContext: {
        runAsNonRoot: true
        runAsUser: 999
    }
    volumeMounts: [
        {
            mountPath: "/var/run/argocd"
            name:      "var-files"
        }, {
            mountPath: "/home/argocd/cmp-server/plugins"
            name:      "plugins"
        }, {
            mountPath: "/home/argocd/cmp-server/config/plugin.yaml"
            subPath:   "plugin.yaml"
            name:      "argocd-cmp-cuelang"
        },
    ]
}]

parameters: params.#Params.static