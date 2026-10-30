process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/63/632e6172876a3d3f8763c6f9359d7a02b4b87e090bcecdf4774e319513337376/data'
:         'community.wave.seqera.io/library/python_pip_baysor-cpp_sopabaysor:85c30fc7ddcf34ab' }"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${index}-segmentation_counts.loom"), path("${index}-segmentation_polygons_2d.json"), val(n_patches)

    script:
    """
    export JULIA_NUM_THREADS=${task.cpus} # parallelize within each patch for Baysor >= v0.7

    sopa segmentation baysor ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_counts.loom ${index}-segmentation_counts.loom
    mv ${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_polygons_2d.json ${index}-segmentation_polygons_2d.json
    """
}
