package config

import (
	"tool/cli"
	"list"
	"encoding/yaml"
	"github.com/deepbrook/argocd-cmp-cuelang/params"
	V1 "cue.dev/x/k8s.io/api/core/v1"
)

// Print the plugin's supported parameters to stdout
command: parameters: {
	out: cli.Print & {text: yaml.Marshal(params.#Definitions)}
}

custom_image: *"" | string @tag(image)
use_cm: *"false" | string @tag(cm)
create_cm: yaml.Unmarshal(use_cm) & bool

// Print a patch for argocd-repo-server.
// Available Tags:
// - "image" (string): Image to use for the side-car; defaults to 'ghcr.io/deepbrook/argocd-cmp-cuelang:<version.mod>'
// - "cm" (bool): Whether to mount a configMap; defaults to 'false', as the default image comes with a plugin.yaml baked in. When set to true, a ConfigMap manifest is appended to the output.
command: "patch": {

	patched_template_spec: containers: [V1.#Container & sidecar & {
		if len(custom_image) > 0 {
			image: custom_image
		}
		if create_cm {
			volumeMounts: list.Concat([sidecar.volumeMounts, [{
				mountPath: "/home/argocd/cmp-server/config/plugin.yaml"
				subPath:   "plugin.yaml"
				name:      "argocd-cmp-cuelang"
			}]])
		}
	}]

	if create_cm {
		patched_template_spec: volumes: [{
			name: "argocd-cmp-cuelang"
			configMap: {
				name: "argocd-cmp-cuelang"
				"defaultMode": 420
			}}] & [...V1.#Volume]
	}
	patch: { spec: template: spec: patched_template_spec }

	result: string
	if !create_cm {
		result: yaml.Marshal(patch)
	}
	if create_cm {
		result: yaml.MarshalStream([patch, cm])
	}

	out: cli.Print & {text: result}
}

