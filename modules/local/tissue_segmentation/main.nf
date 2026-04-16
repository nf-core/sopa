process TISSUE_SEGMENTATION {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/sopa:2.2.5--7a8340c1f5d41e34'
        : 'community.wave.seqera.io/library/sopa:2.2.5--77a69d04f8380675'}"

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
