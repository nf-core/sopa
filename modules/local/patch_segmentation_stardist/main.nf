process PATCH_SEGMENTATION_STARDIST {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4b/4bd32528c3d37b7f49f1eb47e4c792ae51d3cc38a792cf832dfd07adf44cd68c/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:df074ee8a42c1e8f' }"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${index}.parquet"), val(n_patches)

    script:
    """
    export KERAS_HOME="\$PWD/.keras"

    sopa segmentation stardist ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/stardist_boundaries/${index}.parquet ${index}.parquet
    """
}
