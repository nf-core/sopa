process TISSUE_SEGMENTATION {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/6c/6cb46ca65a819a047e6b5d31d220aadeb601080397b1ab5128f4f02442618c87/data'
:         'community.wave.seqera.io/library/python_sopa:43202e226371b17f' }"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)

    script:
    """
    sopa segmentation tissue ${sdata_path} ${cli_arguments}
    """
}
