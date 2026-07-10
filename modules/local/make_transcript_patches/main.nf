process MAKE_TRANSCRIPT_PATCHES {
    label "process_medium"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:19733aca7d06388e'
        : 'community.wave.seqera.io/library/python_sopa:7cebdd875c140064'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path), path("patches_file_transcripts")

    script:
    """
    sopa patchify transcripts ${sdata_path} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/patches_file_transcripts patches_file_transcripts
    """
}
