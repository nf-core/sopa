process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"
    label "process_gpu"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a7/a78efe857b2648962ab27574b503765c37be7d880bf2f3e6d3594d3c4816abe5/data'
:         'community.wave.seqera.io/library/python_sopa_cellpose:29454c8abf082ba0' }"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches), path(model_dir)

    output:
    tuple val(meta), path(sdata_path), path("${index}.parquet"), val(n_patches)

    script:
    """
    export CELLPOSE_LOCAL_MODELS_PATH=${model_dir}

    sopa segmentation cellpose ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/cellpose_boundaries/${index}.parquet ${index}.parquet
    """
}
