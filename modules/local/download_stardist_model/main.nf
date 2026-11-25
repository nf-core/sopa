process DOWNLOAD_STARDIST_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5d/5d25e30a2e73e30ef082ed0890957791b8b4d48d0d4ed873aac7a1cdb7dcd092/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:1c2a51a10a6648c1' }"

    input:
    val cli_arguments

    output:
    path "stardist_models"

    script:
    """
    mkdir -p ./stardist_models

    sopa download stardist --model-dir ./stardist_models ${cli_arguments}
    """
}
