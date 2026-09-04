process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9b/9b2aff8ce764de0716b2334a7c509c21eb85c6eced0335bdd79d16f13a267155/data'
:         'community.wave.seqera.io/library/python_pip_baysor_sopabaysor:cea6739e3ff66418' }"

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
