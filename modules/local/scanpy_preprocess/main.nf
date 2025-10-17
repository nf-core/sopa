process SCANPY_PREPROCESS {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.6'
        : 'docker.io/quentinblampey/sopa:2.1.6'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/tables/table"
    path "versions.yml"

    script:
    """
    sopa scanpy-preprocess ${sdata_path} ${cli_arguments}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        scanpy: \$(python -c "import scanpy; print(scanpy.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
