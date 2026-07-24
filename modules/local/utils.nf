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
            prior_shapes_key: getProsegPriorShapesKey(),
        ]
    } else if (group == "cellpose") {
        return [
            diameter: args.cellpose_diameter,
            channels: getChannels(args.cellpose_channels, false),
            flow_threshold: args.flow_threshold,
            model_type: args.cellpose_model_type,
            pretrained_model: args.pretrained_model,
            gpu: args.cellpose_use_gpu,
            min_area: args.min_area_pixels2,
            clip_limit: args.clip_limit,
            clahe_kernel_size: args.clahe_kernel_size,
            gaussian_sigma: args.gaussian_sigma,
            method_kwargs: args.cellpose_kwargs,
        ]
    } else if (group == "stardist") {
        return [
            model_type: args.stardist_model_type,
            prob_thresh: args.prob_thresh,
            nms_thresh: args.nms_thresh,
            channels: getChannels(args.stardist_channels, true),
            min_area: args.min_area_pixels2,
            clip_limit: args.clip_limit,
            clahe_kernel_size: args.clahe_kernel_size,
            gaussian_sigma: args.gaussian_sigma,
            method_kwargs: args.stardist_kwargs,
        ]
    } else if (group == "baysor") {
        return [
            config: [
                data: [
                    x: "x",
                    y: "y",
                    z: "z",
                    force_2d: args.force_2d,
                    min_molecules_per_cell: args.min_molecules_per_cell,
                    min_molecules_per_gene: args.min_molecules_per_gene,
                    min_molecules_per_segment: args.min_molecules_per_segment,
                    confidence_nn_id: args.confidence_nn_id,
                ],
                segmentation: [
                    scale: args.baysor_scale,
                    scale_std: args.baysor_scale_std,
                    prior_segmentation_confidence: args.prior_segmentation_confidence,
                ],
            ],
            min_area: args.min_area_microns2,
        ]
    } else if (group == "comseg") {
        return [
            config: [
                dict_scale: [
                    x: 1,
                    y: 1,
                    z: 1,
                ],
                allow_disconnected_polygon: args.allow_disconnected_polygon,
                norm_vector: args.norm_vector,
                mean_cell_diameter: args.mean_cell_diameter,
                max_cell_radius: args.max_cell_radius,
                alpha: args.alpha,
                min_rna_per_cell: args.min_rna_per_cell,
            ],
            min_area: args.min_area_microns2,
        ]
    } else if (group == "aggregate") {
        return [
            aggregate_genes: args.aggregate_genes,
            aggregate_channels: args.aggregate_channels,
            expand_radius_ratio: args.expand_radius_ratio,
            min_transcripts: args.min_transcripts,
            min_intensity_ratio: args.min_intensity_ratio,
        ]
    } else if (group == "tissue_segmentation") {
        return [
            level: args.level,
            mode: args.mode,
            kwargs: args.tissue_segmentation_kwargs,
        ]
    } else if (group == "resolve") {
        return [
            min_area: args.min_area_microns2,
        ]
    } else if (group == "transcript_patches") {
        return [
            patch_width_microns: args.patch_width_microns,
            patch_overlap_microns: args.patch_overlap_microns,
            unassigned_value: args.unassigned_value,
            prior_shapes_key: getPriorShapesKey(),
        ]
    } else if (group == "image_patches") {
        return [
            patch_width_pixel: args.patch_width_pixel,
            patch_overlap_pixel: args.patch_overlap_pixel,
            scale: args.image_scale,
        ]
    } else if (group == "fluorescence_annotation") {
        return [
            cell_type_key: args.fluorescence_cell_type_key,
            marker_cell_dict: args.marker_cell_dict,
        ]
    } else if (group == "scanpy_preprocessing") {
        return [
            resolution: args.resolution,
            check_counts: args.check_counts,
            hvg: args.hvg,
        ]
    } else if (group == "explorer") {
        return [
            pixel_size: args.pixel_size,
            ram_threshold_gb: args.ram_threshold_gb,
            lazy: args.lazy,
        ]
    } else {
        exit 1, "Unknown argument group: ${group}"
    }
}

def getPriorShapesKey() {
    if (params.prior_shapes_key != null) {
        return params.prior_shapes_key
    } else {
        return params.use_cellpose ? "cellpose_boundaries" : null
    }
}

def getProsegPriorShapesKey() {
    if (params.visium_hd_prior_shapes_key != null) {
        return params.visium_hd_prior_shapes_key
    } else {
        return params.use_stardist ? "stardist_boundaries" : null
    }
}

def getChannels(String channels, Boolean allow_null = false) {
    if (channels instanceof String) {
        return channels.split(/[ ,|]+/).findAll { it }
    } else {
        if (allow_null && channels == null) {
            return null
        }
        exit 1, "The channels parameter must be a string of channel names separated by space, comma or pipe characters."
    }
}

def argsCLI(String group = null, Map args = null) {
    args = args ?: params

    if (group != null) {
        args = extractSubArgs(args, group)
    }

    return args
        .findAll { _key, _value -> _value != null }
        .collect { key, value -> stringifyItem(key, value) }
        .join(" ")
}

def extractOutsDir(file) {
    if (file.name == 'outs') {
        return file
    }
    return extractOutsDir(file.parent)
}

def argsToSpatialData(Map meta, String fullres_image_file) {
    def args = [
        technology: params.technology,
        kwargs: [:],
    ]

    if (params.visium_hd_imread_page != null) {
        args.kwargs['imread_kwargs'] = ["page": params.visium_hd_imread_page]
    }

    if (params.technology == "visium_hd") {
        args.kwargs["dataset_id"] = meta.id
        args.kwargs["fullres_image_file"] = fullres_image_file
    }

    return argsCLI(null, args)
}

def argsExplorerRaw(String raw_data_path) {
    def args = extractSubArgs(params, "explorer")

    if (params.technology == "xenium") {
        args["raw_data_path"] = raw_data_path
    }

    return argsCLI(null, args)
}
