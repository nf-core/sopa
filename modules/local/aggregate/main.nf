process AGGREGATE {
    label "process_medium"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:3a64d90551e67cae'
        : 'community.wave.seqera.io/library/python_sopa:63c5d58df2bdd5c5'}"

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
