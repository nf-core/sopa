def stringifyItem(String key, value) {
    key = key.replace('_', '-')

    def option = "--${key}"

    if (value instanceof Boolean) {
        return value ? option : "--no-${key}"
    }
    if (value instanceof List) {
        return value.collect { v -> "${option} ${stringifyValueForCli(v)}" }.join(" ")
    }
    return "${option} ${stringifyValueForCli(value)}"
}

def stringifyValueForCli(value) {
    if (value instanceof String || value instanceof Map) {
        return "'${value}'"
    }
    return value.toString()
}

def mapToCliArgs(Map params) {
    return params.collect { key, value -> stringifyItem(key, value) }.join(" ")
}

def readConfigFile(String config) {
    return new groovy.yaml.YamlSlurper().parse(config as File)
}
