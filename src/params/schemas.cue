package params

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
	"string":       string
}

#ArrayParameterDefinition: #ParameterDefinition & {
	collectionType: "array"
	"array": [...string]
}
