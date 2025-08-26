def stringifyItem(String key, value) {
    key = key.replace('_', '-')

    def option = "--${key}"

    if (value instanceof Boolean) {
        return value ? option : "--no-${key}"
    }
    if (value instanceof List) {
        return value.collect { v -> "${option} ${stringifyValueForCli(v)}" }.join(" ")
    }
    if (value instanceof Map) {
        return "${option} \"" + stringifyValueForCli(value) + "\""
    }
    return "${option} ${stringifyValueForCli(value)}"
}

def stringifyValueForCli(value) {
    if (value instanceof Map) {
        return "{" + value.collect { k, v -> "'${k}': ${stringifyValueForCli(v)}" }.join(", ") + "}"
    }
    if (value instanceof List) {
        return "[" + value.collect { stringifyValueForCli(it) }.join(", ") + "]"
    }
    if (value instanceof String) {
        return "'${value}'"
    }
    if (value instanceof Boolean) {
        return value ? "True" : "False"
    }
    if (value instanceof Number) {
        return value.toString()
    }
    return "'${value.toString()}'"
}

def ArgsCLI(Map params, String contains = null, List keys = null) {
    params = params ?: [:]

    return params
        .findAll { key, _value ->
            (contains == null || key.contains(contains)) && (keys == null || key in keys)
        }
        .collect { key, value -> stringifyItem(key, value) }
        .join(" ")
}

def ArgsReaderCLI(Map args, Map meta) {
    if (args.technology == "visium_hd") {
        args = deepCopyCollection(args)

        if (!args.kwargs) {
            args.kwargs = ["dataset_id": meta.id]
        }
        else {
            args.kwargs["dataset_id"] = meta.id
        }

        if (meta.image) {
            args.kwargs["fullres_image_file"] = meta.image
        }
    }

    return ArgsCLI(args)
}

def deepCopyCollection(object) {
    if (object instanceof Map) {
        object.collectEntries { key, value ->
            [key, deepCopyCollection(value)]
        }
    }
    else if (object instanceof List) {
        object.collect { item ->
            deepCopyCollection(item)
        }
    }
    else {
        object
    }
}
