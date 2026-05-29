process AGGREGATE {
    label "process_medium"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:b18f7051c113391d'
        : 'community.wave.seqera.io/library/python_sopa:271022a587d06a6e'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)

    script:
    """
    sopa aggregate ${sdata_path} ${cli_arguments}
    """
}
