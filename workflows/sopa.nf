/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sopa_pipeline'
include { PATCH_SEGMENTATION_BAYSOR ; RESOLVE_BAYSOR } from '../modules/local/baysor'
include { PATCH_SEGMENTATION_CELLPOSE ; RESOLVE_CELLPOSE } from '../modules/local/cellpose'
include { PATCH_SEGMENTATION_STARDIST ; RESOLVE_STARDIST } from '../modules/local/stardist'
include { PATCH_SEGMENTATION_PROSEG } from '../modules/local/proseg'
include {
    TO_SPATIALDATA ;
    TISSUE_SEGMENTATION ;
    MAKE_IMAGE_PATCHES ;
    MAKE_TRANSCRIPT_PATCHES ;
    AGGREGATE ;
    EXPLORER ;
    EXPLORER_RAW ;
    REPORT
} from '../modules/local/sopa_core'
include { readConfigFile } from '../modules/local/utils'
include { ArgsCLI } from '../modules/local/utils'
include { ArgsReaderCLI } from '../modules/local/utils'
include { SPACERANGER } from '../subworkflows/local/spaceranger'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SOPA {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    configfile // sopa configfile  from --configfile

    main:

    ch_versions = Channel.empty()

    def config = readConfigFile(configfile)

    if (config.read.technology == "visium_hd") {
        (ch_input_spatialdata, versions) = SPACERANGER(ch_samplesheet)
        ch_input_spatialdata = ch_input_spatialdata.map { meta, out -> [meta, [out[0].toString().replaceFirst(/(.*?outs).*/, '$1'), meta.image]] }

        ch_versions = ch_versions.mix(versions)
    }
    else {
        ch_input_spatialdata = ch_samplesheet.map { meta -> [meta, meta.data_dir] }
    }

    (ch_spatialdata, versions) = TO_SPATIALDATA(ch_input_spatialdata, config.read)
    ch_versions = ch_versions.mix(versions)

    EXPLORER_RAW(ch_spatialdata, ArgsCLI(config.explorer))

    if (config.segmentation.tissue) {
        (ch_tissue_seg, _out) = TISSUE_SEGMENTATION(ch_spatialdata, ArgsCLI(config.segmentation.tissue))
    }
    else {
        ch_tissue_seg = ch_spatialdata
    }

    if (config.segmentation.cellpose) {
        (ch_image_patches, _out) = MAKE_IMAGE_PATCHES(ch_tissue_seg, ArgsCLI(config.patchify, "pixel"))
        (ch_resolved, versions) = CELLPOSE(ch_image_patches, config)

        ch_versions = ch_versions.mix(versions)
    }

    if (config.segmentation.stardist) {
        (ch_image_patches, _out) = MAKE_IMAGE_PATCHES(ch_tissue_seg, ArgsCLI(config.patchify, "pixel"))
        (ch_resolved, versions) = STARDIST(ch_image_patches, config)

        ch_versions = ch_versions.mix(versions)
    }

    if (config.segmentation.baysor) {
        ch_input_baysor = config.segmentation.cellpose ? ch_resolved : ch_tissue_seg

        ch_transcripts_patches = MAKE_TRANSCRIPT_PATCHES(ch_input_baysor, transcriptPatchesArgs(config, "baysor"))
        (ch_resolved, versions) = BAYSOR(ch_transcripts_patches, config)

        ch_versions = ch_versions.mix(versions)
    }

    if (config.segmentation.proseg) {
        ch_input_proseg = config.segmentation.cellpose ? ch_resolved : ch_tissue_seg

        ch_proseg_patches = MAKE_TRANSCRIPT_PATCHES(ch_input_proseg, transcriptPatchesArgs(config, "proseg"))
        (ch_resolved, versions) = PROSEG(ch_proseg_patches.map { meta, sdata_path, _file -> [meta, sdata_path] }, config)

        ch_versions = ch_versions.mix(versions)
    }

    (ch_aggregated, _out) = AGGREGATE(ch_resolved, ArgsCLI(config.aggregate))

    EXPLORER(ch_aggregated, ArgsCLI(config.explorer))
    REPORT(ch_aggregated)

    PUBLISH(ch_aggregated.map { it[1] })


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions).collectFile(
        storeDir: "${params.outdir}/pipeline_info",
        name: 'nf_core_sopa_software_mqc_versions.yml',
        sort: true,
        newLine: true,
    )

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}

process PUBLISH {
    label "process_single"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    path sdata_path

    output:
    path sdata_path

    script:
    """
    rm -r ${sdata_path}/.sopa_cache || true

    echo "Publishing ${sdata_path}"
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SEGMENTATION WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CELLPOSE {
    take:
    ch_patches
    config

    main:
    ch_versions = Channel.empty()

    cellpose_args = ArgsCLI(config.segmentation.cellpose)

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, cellpose_args, index, n_patches] } }
        .set { ch_cellpose }

    ch_segmented = PATCH_SEGMENTATION_CELLPOSE(ch_cellpose).map { meta, sdata_path, _out, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out, versions) = RESOLVE_CELLPOSE(ch_segmented)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

workflow STARDIST {
    take:
    ch_patches
    config

    main:
    ch_versions = Channel.empty()

    stardist_args = ArgsCLI(config.segmentation.stardist)

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, stardist_args, index, n_patches] } }
        .set { ch_stardist }

    ch_segmented = PATCH_SEGMENTATION_STARDIST(ch_stardist).map { meta, sdata_path, _out, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out, versions) = RESOLVE_STARDIST(ch_segmented)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

workflow PROSEG {
    take:
    ch_patches
    config

    main:
    ch_versions = Channel.empty()

    proseg_args = ArgsCLI(config.segmentation.proseg, null, ["command_line_suffix"])

    (ch_segmented, _out, versions) = PATCH_SEGMENTATION_PROSEG(ch_patches, proseg_args)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_segmented
    ch_versions
}


workflow BAYSOR {
    take:
    ch_patches
    config

    main:
    ch_versions = Channel.empty()

    baysor_args = ArgsCLI(config.segmentation.baysor, null, ["config"])

    ch_patches
        .map { meta, sdata_path, patches_file_transcripts -> [meta, sdata_path, patches_file_transcripts.splitText()] }
        .flatMap { meta, sdata_path, patches_indices -> patches_indices.collect { index -> [meta, sdata_path, baysor_args, index.trim().toInteger(), patches_indices.size] } }
        .set { ch_baysor }

    ch_segmented = PATCH_SEGMENTATION_BAYSOR(ch_baysor).map { meta, sdata_path, _out, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out, versions) = RESOLVE_BAYSOR(ch_segmented, resolveArgs(config))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}

def transcriptPatchesArgs(Map config, String method) {
    def prior_args = ArgsCLI(config.segmentation[method], null, ["prior_shapes_key", "unassigned_value"])

    return ArgsCLI(config.patchify, "micron") + " " + prior_args
}

def resolveArgs(Map config) {
    def gene_column = config.segmentation.baysor.config.data.gene
    def min_area = config.segmentation.baysor.min_area ?: 0

    return "--gene-column ${gene_column} --min-area ${min_area}"
}
