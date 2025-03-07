/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sopa_pipeline'
include { cellpose } from '../subworkflows/local/cellpose'
include { readConfigFile } from '../modules/local/utils'
include { mapToCliArgs } from '../modules/local/utils'
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

    ch_spatialdata = toSpatialData(ch_samplesheet.map { meta -> [meta, meta.sdata_dir] })

    if (config.segmentation.tissue) {
        (ch_tissue_seg, _out) = tissueSegmentation(ch_spatialdata, mapToCliArgs(config.segmentation.tissue))
    }
    else {
        ch_tissue_seg = ch_spatialdata
    }

    (ch_patches, _out) = makeImagePatches(ch_tissue_seg, mapToCliArgs(config.patchify))

    ch_resolved = cellpose(ch_patches, config)

    (ch_aggregated, _out) = aggregate(ch_resolved)

    report(ch_aggregated)
    explorer(ch_aggregated, mapToCliArgs(config.explorer))


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
        .set { ch_collated_versions }

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}


process toSpatialData {
    publishDir 'results', mode: 'copy'

    input:
    tuple val(meta), val(sdata_dir)

    output:
    tuple val(meta), path(sdata_dir)

    script:
    """
    sopa convert . --sdata-path ${meta.sdata_dir} --technology toy_dataset --kwargs '{"length": 200}'
    """
}

process tissueSegmentation {
    publishDir 'results', mode: 'copy'

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
    publishDir 'results', mode: 'copy'

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

process aggregate {
    publishDir 'results', mode: 'copy'

    input:
    tuple val(meta), path(sdata_path)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table"

    script:
    """
    sopa aggregate ${sdata_path}
    """
}

process explorer {
    publishDir 'results', mode: 'copy'

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    path "${meta.explorer_dir}/experiment.xenium"
    path "${meta.explorer_dir}/morphology.ome.tif"
    path "${meta.explorer_dir}/cell_feature_matrix.zarr.zip"
    path "${meta.explorer_dir}/cells.zarr.zip"
    path "${meta.explorer_dir}/transcripts.zarr.zip"
    path "${meta.explorer_dir}/adata.h5ad"

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${cli_arguments}
    """
}

process report {
    publishDir 'results', mode: 'copy'

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
