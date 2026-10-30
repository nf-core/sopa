process PATCH_SEGMENTATION_STARDIST {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/3d/3df38af191764546ee559e447ae66344dbe389599604cf91b411585411a22726/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:ee5a828b73a4e6b5' }"

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
