process SCANPY_PREPROCESS {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b860a96dd8283cde996464a8aaee98a1094be86a6285193f2919c8a59a106a99/data'
:         'community.wave.seqera.io/library/python_sopa:e01bf52e9d748218' }"

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
