package config

import (
	"github.com/deepbrook/argocd-cmp-cuelang:plugin"
)

sidecar: {
	name: "cuelang"
	command: ["/var/run/argocd/argocd-cmp-server"]
	image: string | *"ghcr.io/deepbrook/argocd-cmp-cuelang:\(plugin.version)"
	securityContext: {
		runAsNonRoot: true
		runAsUser:    999
	}
	env: [{ name: "CUE_CACHE_DIR", value: "/opt/cue"}]
	volumeMounts: [
		{
			mountPath: "/var/run/argocd"
			name:      "var-files"
		}, {
			mountPath: "/home/argocd/cmp-server/plugins"
			name:      "plugins"
		}, {
			mountPath: "/tmp"
			name:      "cmp-tmp"
		},
		...
	]
}
