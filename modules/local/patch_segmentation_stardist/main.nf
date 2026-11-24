process PATCH_SEGMENTATION_STARDIST {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5d/5d25e30a2e73e30ef082ed0890957791b8b4d48d0d4ed873aac7a1cdb7dcd092/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:1c2a51a10a6648c1' }"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches), path(model_dir)

    output:
    tuple val(meta), path(sdata_path), path("${index}.parquet"), val(n_patches)

    script:
    """
    export KERAS_HOME=${model_dir}

    sopa segmentation stardist ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/stardist_boundaries/${index}.parquet ${index}.parquet
    """
}
