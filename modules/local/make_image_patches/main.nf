process MAKE_IMAGE_PATCHES {
    label "process_single"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/6c/6cb46ca65a819a047e6b5d31d220aadeb601080397b1ab5128f4f02442618c87/data'
:         'community.wave.seqera.io/library/python_sopa:43202e226371b17f' }"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path), path("patches_file_image")

    script:
    """
    sopa patchify image ${sdata_path} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/patches_file_image patches_file_image
    """
}
