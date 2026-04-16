process SCANPY_PREPROCESS {
    label "process_high"
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
