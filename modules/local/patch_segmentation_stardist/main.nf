process PATCH_SEGMENTATION_STARDIST {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.6-stardist'
        : 'docker.io/quentinblampey/sopa:2.1.6-stardist'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/stardist_boundaries/${index}.parquet"), val(n_patches)

    script:
    """
    sopa segmentation stardist ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}
