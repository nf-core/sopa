/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sopa_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SOPA {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()

    def config = readConfigFile("toy/cellpose.yaml")

    sdata_dirs = ch_samplesheet.map { row -> row[3] }

    sdata_path = toSpatialData(sdata_dirs)

    tissue_seg = config.segmentation.tissue ? tissueSegmentation(sdata_path, mapToCliArgs(config.segmentation.tissue)) : ""

    makeImagePatches(tissue_seg, sdata_path, mapToCliArgs(config.patchify))

    cellpose_args = mapToCliArgs(config.segmentation.cellpose)

    sdata_path
        .merge(makeImagePatches.out.patches_file_image)
        .flatMap { zarr, index_file -> (0..<index_file.text.trim().toInteger()).collect { index -> tuple(zarr, cellpose_args, index) } }
        .set {  -> cellpose_ch }

    patchSegmentationCellpose(cellpose_ch).set {  -> resolve_trigger }

    // aggregate_trigger = resolveCellpose(resolve_trigger, sdata_path)

    // is_aggregated = aggregate(aggregate_trigger, sdata_path)

    // report(is_aggregated, sdata_path, explorer_directory)
    // explorer(is_aggregated, sdata_path, explorer_directory, mapToCliArgs(config.explorer))


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_' + 'sopa_software_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set {  -> ch_collated_versions }

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}


process toSpatialData {
    publishDir 'results', mode: 'copy'

    input:
    val sdata_path

    output:
    path sdata_path, emit: sdata_path

    script:
    """
    sopa convert . --sdata-path ${sdata_path} --technology toy_dataset
    """
}

process tissueSegmentation {
    publishDir 'results', mode: 'copy'

    input:
    path sdata_path
    val cli_arguments

    output:
    path "${sdata_path}/shapes/region_of_interest"

    script:
    """
    sopa segmentation tissue ${sdata_path} ${cli_arguments}
    """
}

process makeImagePatches {
    publishDir 'results', mode: 'copy'

    input:
    val trigger
    path sdata_path
    val cli_arguments

    output:
    path "${sdata_path}/shapes/image_patches"
    path "${sdata_path}/.sopa_cache/patches_file_image", emit: patches_file_image

    script:
    """
    sopa patchify image ${sdata_path} ${cli_arguments}
    """
}

process patchSegmentationCellpose {
    publishDir 'results', mode: 'copy'

    input:
    tuple path(sdata_path), val(cli_arguments), val(index)

    output:
    path "${sdata_path}/.sopa_cache/cellpose_boundaries/${index}.parquet"

    script:
    """
    sopa segmentation cellpose ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process resolveCellpose {
    publishDir 'results', mode: 'copy'

    input:
    val trigger
    path sdata_path

    output:
    path "${sdata_path}/shapes/cellpose_boundaries"

    script:
    """
    sopa resolve cellpose ${sdata_path}
    """
}

process aggregate {
    publishDir 'results', mode: 'copy'

    input:
    val trigger
    path sdata_path

    output:
    path "${sdata_path}/tables/table"

    script:
    """
    sopa aggregate ${sdata_path}
    """
}

process explorer {
    publishDir 'results', mode: 'copy'

    input:
    val trigger
    path sdata_path
    path explorer_experiment
    val cli_arguments

    output:
    path "${explorer_experiment}/experiment.xenium"

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${explorer_experiment} ${cli_arguments}
    """
}

process report {
    publishDir 'results', mode: 'copy'

    input:
    val trigger
    path sdata_path
    path explorer_directory

    output:
    path "${explorer_directory}/analysis_summary.html"

    script:
    """    
    sopa report ${sdata_path} ${explorer_directory}/analysis_summary.html
    """
}

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
