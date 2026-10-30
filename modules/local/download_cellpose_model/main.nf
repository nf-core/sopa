process DOWNLOAD_CELLPOSE_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/1c/1c06334f438946057dc2acdc6580080d740a9b416f479035302c898f055fda8b/data'
:         'community.wave.seqera.io/library/python_sopa_cellpose:b504a8c810aa7c01' }"

    input:
    val cli_arguments

    output:
    path "cellpose_models"

    script:
    """
    mkdir -p ./cellpose_models

    sopa download cellpose --model-dir ./cellpose_models ${cli_arguments}
    """
}
