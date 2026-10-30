process DOWNLOAD_STARDIST_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/3d/3df38af191764546ee559e447ae66344dbe389599604cf91b411585411a22726/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:ee5a828b73a4e6b5' }"

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
