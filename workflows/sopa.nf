/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sopa_pipeline'

include { TO_SPATIALDATA } from '../modules/local/to_spatialdata'
include { MAKE_IMAGE_PATCHES } from '../modules/local/make_image_patches'
include { MAKE_TRANSCRIPT_PATCHES } from '../modules/local/make_transcript_patches'
include { TISSUE_SEGMENTATION } from '../modules/local/tissue_segmentation'
include { PATCH_SEGMENTATION_BAYSOR } from '../modules/local/patch_segmentation_baysor'
include { PATCH_SEGMENTATION_COMSEG } from '../modules/local/patch_segmentation_comseg'
include { PATCH_SEGMENTATION_CELLPOSE } from '../modules/local/patch_segmentation_cellpose'
include { PATCH_SEGMENTATION_STARDIST } from '../modules/local/patch_segmentation_stardist'
include { PATCH_SEGMENTATION_PROSEG } from '../modules/local/patch_segmentation_proseg'
include { RESOLVE_BAYSOR } from '../modules/local/resolve_baysor'
include { RESOLVE_COMSEG } from '../modules/local/resolve_comseg'
include { RESOLVE_CELLPOSE } from '../modules/local/resolve_cellpose'
include { RESOLVE_STARDIST } from '../modules/local/resolve_stardist'
include { AGGREGATE } from '../modules/local/aggregate'
include { EXPLORER } from '../modules/local/explorer'
include { EXPLORER_RAW } from '../modules/local/explorer_raw'
include { SCANPY_PREPROCESS } from '../modules/local/scanpy_preprocess'
include { REPORT } from '../modules/local/report'
include { TANGRAM_ANNOTATION } from '../modules/local/tangram_annotation'
include { FLUO_ANNOTATION } from '../modules/local/fluo_annotation'
include { SPACERANGER } from '../subworkflows/local/spaceranger'
include { argsCLI } from '../modules/local/utils'
include { extractOutsDir } from '../modules/local/utils'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SOPA {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = channel.empty()

    if (params.technology == "visium_hd") {
        (ch_input_spatialdata, versions) = SPACERANGER(ch_samplesheet)
        ch_input_spatialdata = ch_input_spatialdata.map { meta, out -> [meta, extractOutsDir(out[0]), meta.image] }

        ch_versions = ch_versions.mix(versions)
    }
    else {
        ch_input_spatialdata = ch_samplesheet.map { meta -> [meta, meta.data_dir, []] }
    }

    (ch_spatialdata, versions) = TO_SPATIALDATA(ch_input_spatialdata)
    ch_versions = ch_versions.mix(versions)

    ch_explorer_raw = ch_spatialdata.map { meta, sdata_path -> [meta, sdata_path, params.technology == "xenium" ? meta.data_dir : []] }
    EXPLORER_RAW(ch_explorer_raw)

    if (params.use_tissue_segmentation) {
        (ch_tissue_seg, _out) = TISSUE_SEGMENTATION(ch_spatialdata, argsCLI("tissue_segmentation"))
    }
    else {
        ch_tissue_seg = ch_spatialdata
    }

    if (params.use_cellpose) {
        (ch_image_patches, _out) = MAKE_IMAGE_PATCHES(ch_tissue_seg, argsCLI("image_patches"))
        (ch_resolved, versions) = CELLPOSE(ch_image_patches)

        ch_versions = ch_versions.mix(versions)
    }

    if (params.use_stardist) {
        (ch_image_patches, _out) = MAKE_IMAGE_PATCHES(ch_tissue_seg, argsCLI("image_patches"))
        (ch_resolved, versions) = STARDIST(ch_image_patches)

        ch_versions = ch_versions.mix(versions)
    }

    if (params.use_baysor) {
        ch_input_baysor = params.use_cellpose ? ch_resolved : ch_tissue_seg

        ch_transcripts_patches = MAKE_TRANSCRIPT_PATCHES(ch_input_baysor, argsCLI("transcript_patches"))
        (ch_resolved, versions) = BAYSOR(ch_transcripts_patches)

        ch_versions = ch_versions.mix(versions)
    }

    if (params.use_comseg) {
        ch_input_comseg = params.use_cellpose ? ch_resolved : ch_tissue_seg

        ch_transcripts_patches = MAKE_TRANSCRIPT_PATCHES(ch_input_comseg, argsCLI("transcript_patches") + " --write-cells-centroids")
        (ch_resolved, versions) = COMSEG(ch_transcripts_patches)

        ch_versions = ch_versions.mix(versions)
    }

    if (params.use_proseg) {
        if (params.use_stardist) {
            if (!params.technology == "visium_hd") {
                error("Proseg segmentation with StarDist prior shapes is only supported for Visium HD data.")
            }
            ch_input_proseg = ch_resolved.map { meta, sdata_path -> [meta, sdata_path, [], []] }
        } else {
            ch_proseg_patches = params.use_cellpose ? ch_resolved : ch_tissue_seg
            ch_input_proseg = MAKE_TRANSCRIPT_PATCHES(ch_proseg_patches, argsCLI("transcript_patches"))
        }

        (ch_resolved, versions) = PROSEG(ch_input_proseg)

        ch_versions = ch_versions.mix(versions)
    }

    (ch_aggregated, _out) = AGGREGATE(ch_resolved, argsCLI("aggregate"))

    if (params.use_tangram) {
        sc_reference = file(params.sc_reference_path)

        (ch_annotated, _out, versions) = TANGRAM_ANNOTATION(ch_aggregated, sc_reference, argsCLI("tangram"))
        ch_versions = ch_versions.mix(versions)
    }
    else if (params.use_fluorescence_annotation) {
        (ch_annotated, _out, versions) = FLUO_ANNOTATION(ch_aggregated, argsCLI("fluorescence_annotation"))
        ch_versions = ch_versions.mix(versions)
    }
    else {
        ch_annotated = ch_aggregated
    }

    if (params.use_scanpy_preprocessing) {
        (ch_preprocessed, _out, versions) = SCANPY_PREPROCESS(ch_annotated, argsCLI("scanpy_preprocessing"))
        ch_versions = ch_versions.mix(versions)
    }
    else {
        ch_preprocessed = ch_annotated
    }

    EXPLORER(ch_preprocessed, argsCLI("explorer"))

    REPORT(ch_preprocessed)

    //
    // Collate and save software versions
    //
    def topic_versions = Channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_sopa_software_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SEGMENTATION WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CELLPOSE {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    cellpose_args = argsCLI("cellpose")

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, cellpose_args, index, n_patches] } }
        .set { ch_cellpose }

    ch_segmented = PATCH_SEGMENTATION_CELLPOSE(ch_cellpose).map { meta, sdata_path, parquet, n_patches -> [groupKey(meta.sdata_dir, n_patches), meta, sdata_path, parquet] }.groupTuple().map { _key, metas, sdata_paths, parquets -> [metas[0], sdata_paths[0], parquets] }

    (ch_resolved, _out, versions) = RESOLVE_CELLPOSE(ch_segmented)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

workflow STARDIST {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    stardist_args = argsCLI("stardist")

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, stardist_args, index, n_patches] } }
        .set { ch_stardist }

    ch_segmented = PATCH_SEGMENTATION_STARDIST(ch_stardist).map { meta, sdata_path, parquet, n_patches -> [groupKey(meta.sdata_dir, n_patches), meta, sdata_path, parquet] }.groupTuple().map { _key, metas, sdata_paths, parquets -> [metas[0], sdata_paths[0], parquets] }

    (ch_resolved, _out, versions) = RESOLVE_STARDIST(ch_segmented)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}


workflow BAYSOR {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    baysor_args = argsCLI("baysor")

    ch_patches
        .map { meta, sdata_path, patches_file_transcripts, _patches -> [meta, sdata_path, patches_file_transcripts.splitText()] }
        .flatMap { meta, sdata_path, patches_indices -> patches_indices.collect { index -> [meta, sdata_path, baysor_args, index.trim().toInteger(), patches_indices.size] } }
        .set { ch_baysor }

    ch_segmented = PATCH_SEGMENTATION_BAYSOR(ch_baysor).map { meta, sdata_path, _out, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out, versions) = RESOLVE_BAYSOR(ch_segmented, argsCLI("resolve"))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

workflow COMSEG {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    comseg_args = argsCLI("comseg")

    ch_patches
        .map { meta, sdata_path, patches_file_transcripts, _patches -> [meta, sdata_path, patches_file_transcripts.splitText()] }
        .flatMap { meta, sdata_path, patches_indices -> patches_indices.collect { index -> [meta, sdata_path, comseg_args, index.trim().toInteger(), patches_indices.size] } }
        .set { ch_comseg }

    ch_segmented = PATCH_SEGMENTATION_COMSEG(ch_comseg).map { meta, sdata_path, _out1, _out2, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out, versions) = RESOLVE_COMSEG(ch_segmented, argsCLI("resolve"))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

workflow PROSEG {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    (ch_segmented, _out, versions) = PATCH_SEGMENTATION_PROSEG(ch_patches, argsCLI("proseg"))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_segmented
    ch_versions
}
