include { ArgsReaderCLI } from '../utils'

process TO_SPATIALDATA {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

    input:
    tuple val(meta), path(input_files)
    val args

    output:
    tuple val(meta), path("${meta.sdata_dir}")
    path "versions.yml"

    script:
    """
    sopa convert ${meta.data_dir} --sdata-path ${meta.sdata_dir} ${ArgsReaderCLI(args, meta)}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version 2> /dev/null)
        spatialdata: \$(python -c "import spatialdata; print(spatialdata.__version__)" 2> /dev/null)
        spatialdata_io: \$(python -c "import spatialdata_io; print(spatialdata_io.__version__)" 2> /dev/null)
        scanpy: \$(python -c "import scanpy; print(scanpy.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}

process TISSUE_SEGMENTATION {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process MAKE_IMAGE_PATCHES {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process MAKE_TRANSCRIPT_PATCHES {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process AGGREGATE {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process EXPLORER_RAW {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process EXPLORER {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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

process REPORT {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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
