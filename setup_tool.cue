package plugin

import (
	"tool/cli"
	"encoding/yaml"
)

patch: spec: template: spec: {
	containers: [{
		name: "cuelang"
		command: ["/var/run/argocd/argocd-cmp-server"]
		image: "cuelang/cue"
		securityContext: {
			runAsNonRoot: true
			runAsUser:    999
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
			}, {
				mountPath: "/tmp"
				name:      "cmp-tmp"
			},
		]
	}]
	volumes: [
		{configMap: {name: "argocd-cmp-cuelang", "defaultMode": 420}, name: "argocd-cmp-cuelang"},
		{emptyDir: {}, name: "cmp-tmp"},
	]
}

// Print the plugin's supported parameters to stdout
command: parameters: {
	out: cli.Print & {text: yaml.Marshal(#Params.static)}
}
// Print a patch for argocd-repo-server
command: "create-patch": {
	out: cli.Print & {text: yaml.Marshal(patch)}
}

// Print a ConfigMap manifest for use with a patched argocd-repo-server
command: "create-cm": {
	out: cli.Print & {text: yaml.Marshal(cm)}
}
