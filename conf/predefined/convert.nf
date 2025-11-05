def convert(v) {
    if (v instanceof Map) {
        return '[\n' + v.collect { k, val -> "${k}: ${convert(val)}" }.join(', ') + '\n]'
    }
    if (v instanceof List) {
        return '[\n' + v.collect { convert(it) }.join(', ') + '\n]'
    }
    if (v instanceof String) {
        return "'${v.replace("'", "\\'")}'"
    }
    if (v == null) {
        return 'null'
    }
    return v.toString()
}

workflow {
    def output = params.output

    params.remove('output')

    new File(output).text = "params {\n  " + params.collect { k, v -> "${k} = ${convert(v)}" }.join('\n  ') + "\n}\n"
}
