process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_pip_baysor_sopabaysor:70f197848d1b79c5'
        : 'community.wave.seqera.io/library/python_pip_baysor_sopabaysor:4a532a683a27bd0f'}"

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
