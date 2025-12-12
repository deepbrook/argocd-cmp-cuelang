package plugin

import "cue.dev/x/k8s.io/api/core/v1"

patch: spec: template: spec: {
	containers: [v1.#Container & {
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
