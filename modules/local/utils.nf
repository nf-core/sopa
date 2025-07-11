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

        println("meta: ${meta}")

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


def validate(Map cfg) {
    def TRANSCRIPT_BASED_METHODS = ['proseg', 'baysor', 'comseg']
    def STAINING_BASED_METHODS = ['stardist', 'cellpose']

    def backwardCompatibility = { Map c ->
        TRANSCRIPT_BASED_METHODS.each { m ->
            if (c.segmentation?.get(m)?.containsKey('cell_key')) {
                println("Deprecated 'cell_key' → using 'prior_shapes_key' instead.")
                c.segmentation[m].prior_shapes_key = c.segmentation[m].cell_key
                c.segmentation[m].remove('cell_key')
            }
        }
        if (c.aggregate?.containsKey('average_intensities')) {
            println("Deprecated 'average_intensities' → using 'aggregate_channels' instead.")
            c.aggregate.aggregate_channels = c.aggregate.average_intensities
            c.aggregate.remove('average_intensities')
        }
    }

    def checkSegmentationMethods = { Map c ->
        assert c.segmentation && c.segmentation : "Provide at least one segmentation method"
        assert TRANSCRIPT_BASED_METHODS.count { c.segmentation.containsKey(it) } <= 1 : "Only one of ${TRANSCRIPT_BASED_METHODS} may be used"
        assert STAINING_BASED_METHODS.count { c.segmentation.containsKey(it) } <= 1 : "Only one of ${STAINING_BASED_METHODS} may be used"
        if (c.segmentation.containsKey('stardist')) {
            assert TRANSCRIPT_BASED_METHODS.every { !c.segmentation.containsKey(it) } : "'stardist' cannot be combined with transcript-based methods"
        }
    }

    def checkPriorShapesKey = { Map c ->
        TRANSCRIPT_BASED_METHODS.each { m ->
            if (c.segmentation.containsKey(m) && c.segmentation.containsKey('cellpose')) {
                c.segmentation[m].prior_shapes_key = 'cellpose_boundaries'
            }
        }
    }

    /* ───────── top-level checks ───────── */
    assert cfg.read instanceof Map && cfg.read.containsKey('technology') : "Provide a 'read.technology' key"
    assert cfg.containsKey('segmentation') : "Provide a 'segmentation' section"

    backwardCompatibility(cfg)
    checkSegmentationMethods(cfg)
    checkPriorShapesKey(cfg)

    return cfg
}
