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

def readConfigFile(String configfile) {
    def reader

    if (configfile ==~ /^https?:\/\/.*/) {
        reader = new InputStreamReader(new URL(configfile).openStream())
    }
    else {
        reader = new File(configfile).newReader()
    }

    def config = new groovy.yaml.YamlSlurper().parse(reader)

    return validate(config)
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


def validate(Map config) {
    def TRANSCRIPT_BASED_METHODS = ['proseg', 'baysor', 'comseg']
    def STAINING_BASED_METHODS = ['stardist', 'cellpose']

    // top-level checks
    assert config.read instanceof Map && config.read.containsKey('technology') : "Provide a 'read.technology' key"
    assert config.containsKey('segmentation') : "Provide a 'segmentation' section"

    // backward compatibility
    TRANSCRIPT_BASED_METHODS.each { m ->
        if (config.segmentation?.get(m)?.containsKey('cell_key')) {
            println("Deprecated 'cell_key' → using 'prior_shapes_key' instead.")
            config.segmentation[m].prior_shapes_key = config.segmentation[m].cell_key
            config.segmentation[m].remove('cell_key')
        }
    }
    if (config.aggregate?.containsKey('average_intensities')) {
        println("Deprecated 'average_intensities' → using 'aggregate_channels' instead.")
        config.aggregate.aggregate_channels = config.aggregate.average_intensities
        config.aggregate.remove('average_intensities')
    }

    // check segmentation methods
    assert config.segmentation : "Provide at least one segmentation method"
    assert TRANSCRIPT_BASED_METHODS.count { config.segmentation.containsKey(it) } <= 1 : "Only one of ${TRANSCRIPT_BASED_METHODS} may be used"
    assert STAINING_BASED_METHODS.count { config.segmentation.containsKey(it) } <= 1 : "Only one of ${STAINING_BASED_METHODS} may be used"
    if (config.segmentation.containsKey('stardist')) {
        assert TRANSCRIPT_BASED_METHODS.every { !config.segmentation.containsKey(it) } : "'stardist' cannot be combined with transcript-based methods"
    }

    // check prior shapes key
    TRANSCRIPT_BASED_METHODS.each { m ->
        if (config.segmentation.containsKey(m) && config.segmentation.containsKey('cellpose')) {
            config.segmentation[m].prior_shapes_key = 'cellpose_boundaries'
        }
    }


    return config
}
