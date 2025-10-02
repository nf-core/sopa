process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-cellpose'
        : 'docker.io/quentinblampey/sopa:latest-cellpose'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/cellpose_boundaries/${index}.parquet"), val(n_patches)

    script:
    """
    mkdir ./cellpose_cache
    export CELLPOSE_LOCAL_MODELS_PATH=./cellpose_cache

    sopa segmentation cellpose ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}
