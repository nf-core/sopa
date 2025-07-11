/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sopa_pipeline'
include { CELLPOSE } from '../subworkflows/local/cellpose'
include { STARDIST } from '../subworkflows/local/stardist'
include { BAYSOR } from '../subworkflows/local/baysor'
include { PROSEG } from '../subworkflows/local/proseg'
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
        ch_input_spatialdata = ch_input_spatialdata.map { meta, out -> [meta, [out.toString().replaceFirst(/(.*?outs).*/, '$1'), meta.image]] }

        ch_versions = ch_versions.mix(versions)
    }
    else {
        ch_input_spatialdata = ch_samplesheet.map { meta -> [meta, meta.data_dir] }
    }

    ch_spatialdata = toSpatialData(ch_input_spatialdata, config.read)

    explorer_raw(ch_spatialdata, ArgsCLI(config.explorer))

    if (config.segmentation.tissue) {
        (ch_tissue_seg, _out) = tissueSegmentation(ch_spatialdata, ArgsCLI(config.segmentation.tissue))
    }
    else {
        ch_tissue_seg = ch_spatialdata
    }

    if (config.segmentation.cellpose) {
        (ch_image_patches, _out) = makeImagePatches(ch_tissue_seg, ArgsCLI(config.patchify, "pixel"))
        ch_resolved = CELLPOSE(ch_image_patches, config)
    }

    if (config.segmentation.stardist) {
        (ch_image_patches, _out) = makeImagePatches(ch_tissue_seg, ArgsCLI(config.patchify, "pixel"))
        ch_resolved = STARDIST(ch_image_patches, config)
    }

    if (config.segmentation.baysor) {
        ch_input_baysor = config.segmentation.cellpose ? ch_resolved : ch_tissue_seg

        ch_transcripts_patches = makeTranscriptPatches(ch_input_baysor, transcriptPatchesArgs(config, "baysor"))
        ch_resolved = BAYSOR(ch_transcripts_patches, config)
    }

    if (config.segmentation.proseg) {
        ch_input_proseg = config.segmentation.cellpose ? ch_resolved : ch_tissue_seg

        ch_proseg_patches = makeTranscriptPatches(ch_input_proseg, transcriptPatchesArgs(config, "proseg"))
        ch_resolved = PROSEG(ch_proseg_patches.map { meta, sdata_path, _file -> [meta, sdata_path] }, config)
    }

    (ch_aggregated, _out) = aggregate(ch_resolved, ArgsCLI(config.aggregate))

    explorer(ch_aggregated, ArgsCLI(config.explorer))
    report(ch_aggregated)

    publish(ch_aggregated.map { it[1] })


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

process toSpatialData {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    input:
    tuple val(meta), path(input_files)
    val args

    output:
    tuple val(meta), path("${meta.sdata_dir}")

    script:
    """
    sopa convert ${meta.data_dir} --sdata-path ${meta.sdata_dir} ${ArgsReaderCLI(args, meta)}
    """
}

process tissueSegmentation {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/region_of_interest"

    script:
    """
    sopa segmentation tissue ${sdata_path} ${cli_arguments}
    """
}

process makeImagePatches {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/patches_file_image")
    path "${sdata_path}/shapes/image_patches"

    script:
    """
    sopa patchify image ${sdata_path} ${cli_arguments}
    """
}

process makeTranscriptPatches {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/patches_file_transcripts")

    script:
    """
    sopa patchify transcripts ${sdata_path} ${cli_arguments}
    """
}

process aggregate {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table"

    script:
    """
    sopa aggregate ${sdata_path} ${cli_arguments}
    """
}

process explorer_raw {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    path "${meta.explorer_dir}/morphology*"
    path "${meta.explorer_dir}/transcripts*", optional: true

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${cli_arguments} --mode "+it" --no-save-h5ad
    """
}

process explorer {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    path "${meta.explorer_dir}/experiment.xenium"
    path "${meta.explorer_dir}/analysis.zarr.zip"
    path "${meta.explorer_dir}/cell_feature_matrix.zarr.zip"
    path "${meta.explorer_dir}/adata.h5ad"
    path "${meta.explorer_dir}/cells.zarr.zip"

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${cli_arguments} --mode "-it"
    """
}

process report {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.0.7'
        : 'docker.io/quentinblampey/sopa:2.0.7'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path)

    output:
    path "${meta.explorer_dir}/analysis_summary.html"

    script:
    """
    mkdir -p ${meta.explorer_dir}

    sopa report ${sdata_path} ${meta.explorer_dir}/analysis_summary.html
    """
}

process publish {
    label "process_single"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    path sdata_path

    output:
    path sdata_path

    script:
    """
    echo "Publishing ${sdata_path}"
    """
}

def transcriptPatchesArgs(Map config, String method) {
    def prior_args = ArgsCLI(config.segmentation[method], null, ["prior_shapes_key", "unassigned_value"])

    return ArgsCLI(config.patchify, "micron") + " " + prior_args
}
