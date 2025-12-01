package params


#CommonParams: {
    tags: {
        id: "tags"
        def: #ArrayParameterDefinition & {
            title: "Injections"
            name: id
            tooltip: "list of key=value items to inject using the `-t` flag."
        }
        val: #ArrayParameterValidation & {
            name: id
        }
    }

    ...

    defaults: [tags.val, ...]
    static: [tags.def, ...]
}