package params

#ParameterDefinition: {
    title: string
    name: string
    tooltip: string
    required: bool | *false
    ...
}

#StringParameterDefinition: #ParameterDefinition & {
    collectionType: "string"
    "string": string | *""
}

#ArrayParameterDefinition: #ParameterDefinition & {
    collectionType: "array"
    "array": [...string] | *[]
}

#ParameterValidation: {
    name!: string
    ...
}
#StringParameterValidation: #ParameterValidation & { "string": string | *"" }
#ArrayParameterValidation: #ParameterValidation & { "array": [...string] | *[] }