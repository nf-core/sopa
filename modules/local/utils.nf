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

def extractSubArgs(Map args, String group) {
    if (group == "proseg") {
        return [
            command_line_suffix: args.command_line_suffix,
            infer_presets: args.infer_presets,
            prior_shapes_key: args.visium_hd_prior_shapes_key,
        ]
    } else if (group == "aggregate") {
        return [
            aggregate_genes: args.aggregate_genes,
            aggregate_channels: args.aggregate_channels,
            min_transcripts: args.min_transcripts,
            min_intensity_ratio: args.min_intensity_ratio,
            expand_radius_ratio: args.expand_radius_ratio,
        ]
    } else if (group == "tissue_segmentation") {
        return [
            level: args.level,
            mode: args.mode,
        ]
    } else if (group == "transcript_patches") {
        return [
            prior_shapes_key: args.prior_shapes_key,
            unassigned_value: args.unassigned_value,
            patch_width_microns: args.patch_width_microns,
            patch_overlap_microns: args.patch_overlap_microns
        ]
    } else if (group == "image_patches") {
        return [
            patch_width_pixels: args.patch_width_pixels,
            patch_overlap_pixels: args.patch_overlap_pixels
        ]
    } else if (group == "tangram") {
        return [
            sc_reference_path: args.sc_reference_path,
            cell_type_key: args.cell_type_key,
            reference_preprocessing: args.reference_preprocessing
        ]
    } else if (group == "scanpy_preprocessing") {
        return [
            check_counts: args.check_counts,
            resolution: args.resolution,
            hvg: args.hvg,
        ]
    } else if (group == "explorer_raw") {
        return [
            pixel_size: args.pixel_size,
            ram_threshold_gb: args.ram_threshold_gb,
            lazy: args.lazy,
        ]
    } else {
        exit 1, "Unknown argument group: ${group}"
    }
}

def argsCLI(Map args = null, String group = null) {
    args = args ?: params

    if (group != null) {
        args = extractSubArgs(args, group)
    }

    return args
        .findAll { _key, _value -> _value != null }
        .collect { key, value -> stringifyItem(key, value) }
        .join(" ")
}

def argsToSpatialData(Map meta, String fullres_image_file) {
    def args = [
        technology: params.technology,
        kwargs: [:],
    ]

    if (params.toy_dataset_genes != null) {
        args.kwargs['genes'] = params.toy_dataset_genes
    }

    if (params.visium_hd_imread_page != null) {
        args.kwargs['imread_kwargs'] = ["page": params.visium_hd_imread_page]
    }

    if (params.technology == "visium_hd") {
        args.kwargs["dataset_id"] = meta.id
        args.kwargs["fullres_image_file"] = fullres_image_file
    }

    return argsCLI(args)
}

def argsExplorerRaw(String raw_data_path) {
    def args = extractSubArgs(params, "explorer_raw")

    if (params.technology == "xenium") {
        args["raw_data_path"] = raw_data_path
    }

    return argsCLI(args)
}
