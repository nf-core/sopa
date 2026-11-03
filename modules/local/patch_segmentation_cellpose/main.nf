process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"
    label "process_gpu"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/1c/1c06334f438946057dc2acdc6580080d740a9b416f479035302c898f055fda8b/data'
:         'community.wave.seqera.io/library/python_sopa_cellpose:b504a8c810aa7c01' }"

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
