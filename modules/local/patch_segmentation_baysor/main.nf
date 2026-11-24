process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9f/9f744655616962e2554ebe76893d2a5f71ba48b21952ca4aa78fcd683a0fbcce/data'
:         'community.wave.seqera.io/library/python_pip_baysor-cpp_sopabaysor:cdbdaf26b3f6bd92' }"

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
