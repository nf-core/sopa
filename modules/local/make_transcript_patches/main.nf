process MAKE_TRANSCRIPT_PATCHES {
    label "process_medium"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/41/41ba11ed68351d07343e61d1aacaf95b61af20a9bb943e2b3c1829507d970dd7/data'
:         'community.wave.seqera.io/library/python_sopa:56fd765d45ba1fcc' }"

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
