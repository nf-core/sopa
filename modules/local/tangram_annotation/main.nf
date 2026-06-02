process TANGRAM_ANNOTATION {
    label "process_gpu"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_pip_sopa_tangram-sc:7e709cd4da9038b2'
        : 'community.wave.seqera.io/library/python_pip_sopa_tangram-sc:1e7964868e6ad761'}"

    input:
    tuple val(meta), path(sdata_path)
    file sc_reference
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
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
