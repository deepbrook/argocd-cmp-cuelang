package config

#CmpConfigBase:{
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ConfigManagementPlugin"
	spec: {
		version: "v0.15.1"

		init: {
			command: ["sh"]
			args: ["-c", "echo", "Initializing.."]
		}

		preserveFileMode: false
		provideGitCreds: false
		...
	}
	...
}