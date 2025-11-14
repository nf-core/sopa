process AGGREGATE {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.9'
        : 'docker.io/quentinblampey/sopa:2.1.9'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table"

    script:
    """
    sopa aggregate ${sdata_path} ${cli_arguments}
    """
}
