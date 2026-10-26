process DOWNLOAD_STARDIST_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4b/4bd32528c3d37b7f49f1eb47e4c792ae51d3cc38a792cf832dfd07adf44cd68c/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:df074ee8a42c1e8f' }"

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
