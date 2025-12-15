package plugin

// Parameter Definition Schemas
#ParameterDefinition: {
	title!:    string
	name!:     string
	tooltip:  string | *""
	required: bool | *false
	...
}

#StringParameterDefinition: #ParameterDefinition & {
	collectionType: "string"
	"string":       string | *""
}

#ArrayParameterDefinition: #ParameterDefinition & {
	collectionType: "array"
	"array": [...string]
}

// Parameter Validation Schemas
#ParameterValidation: {
	name!: string
	...
}
#ArrayParameterValidation: #ParameterValidation & {"array": [...string] | *[]}
#StringParameterValidation: #ParameterValidation & {"string": string | *""}

// Parameter Schema Obj
#Params: {
	"cue-command":  #StringParameterDefinition & {
		title:    "CUE sub-command"
		name:     "cue-command"
		tooltip:  "CUE sub-command to invoke (default: `\(default)`)"
		default="string": "cmd" | *"eval"
	}

	package: #StringParameterDefinition & {
		title:   "CUE Package"
		name:    "package"
		tooltip: "CUE Package to run `cue` with."
	}

	tags: #ArrayParameterDefinition & {
			title:   "Injections"
			name:    "tags"
			tooltip: "list of key=value items to inject using the `-t` flag."
	}

	// `cue eval` only
	output: #StringParameterDefinition & {
			title:    "Format"
			name:     "output"
			tooltip:  "Output format to use when running `cue eval`. Restricted to JSON/YAML/text. When using 'text', please make sure that the result has been encoded to JSON or YAML, as ArgoCD does not accept other formats."
			"string": "json" | "yaml" | *"text"
	}

	expressions: #ArrayParameterDefinition & {
			title:   "Expressions"
			name:    "expressions"
			tooltip: "Expressions to pass to `cue eval` via `-e/--expression` flag (default: none)."
			"array": [...string] | *["manifests"]
	}

	// `cue cmd` only
	workflow: #StringParameterDefinition & {
			title:    "CUE Workflow Command"
			name:     "workflow"
			tooltip:  "Name of the workflow command defined in the `*_tool.cue` file called (default: `\(default)`). Ignored if `cue-command` is `eval`."
			required: false
			default="string": "build"
	}
}

#UNMARSHALLED_ARGOCD_APP_PARAMS: [...matchN(1, [for field, schema in #Params {schema}])]
