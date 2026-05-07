process TISSUE_SEGMENTATION {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:ae2e3bb4a14388f3'
        : 'community.wave.seqera.io/library/python_sopa:835e8c88fff339ab'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)

    script:
    """
    sopa segmentation tissue ${sdata_path} ${cli_arguments}
    """
}
