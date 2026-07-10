process TANGRAM_ANNOTATION {
    label "process_gpu"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/cf/cfb6e981030f878b518ccc562e36cc908cab802197d5e57aa221cddd64d34d3d/data'
:         'community.wave.seqera.io/library/python_pip_sopa_tangram-sc:af0866b42bd9c9b3' }"

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
