process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa_cellpose:881b5601e4fb377d'
        : 'community.wave.seqera.io/library/python_sopa_cellpose:6d37d26c557b9aa8'}"

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
