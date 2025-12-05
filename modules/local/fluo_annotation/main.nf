process FLUO_ANNOTATION {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.10'
        : 'docker.io/quentinblampey/sopa:2.1.10'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table/obs"
    path "versions.yml"

    script:
    """
    sopa annotate fluorescence ${sdata_path} ${cli_arguments}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
    END_VERSIONS
    """
}
