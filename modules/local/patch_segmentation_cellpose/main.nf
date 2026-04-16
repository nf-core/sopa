process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/sopa:2.2.5--7a8340c1f5d41e34-cellpose'
        : 'community.wave.seqera.io/library/sopa:2.2.5--77a69d04f8380675-cellpose'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${index}.parquet"), val(n_patches)

    script:
    """
    mkdir ./cellpose_cache
    export CELLPOSE_LOCAL_MODELS_PATH=./cellpose_cache

    sopa segmentation cellpose ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/cellpose_boundaries/${index}.parquet ${index}.parquet
    """
}
