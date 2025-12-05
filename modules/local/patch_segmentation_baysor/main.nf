process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.10-baysor'
        : 'docker.io/quentinblampey/sopa:2.1.10-baysor'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_counts.loom"), val(n_patches)

    script:
    """
    export JULIA_NUM_THREADS=${task.cpus} # parallelize within each patch for Baysor >= v0.7

    sopa segmentation baysor ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}
