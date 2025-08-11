process TANGRAM_ANNOTATION {
    label "process_gpu"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

    input:
    tuple val(meta), path(sdata_path)
    file sc_reference
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table/obs"
    path "versions.yml"

    script:
    """
    sopa annotate tangram ${sdata_path} --sc-reference-path ${sc_reference} ${cli_arguments}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        tangram: \$(python -c "import tangram; print(tangram.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}

process FLUO_ANNOTATION {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

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
