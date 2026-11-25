process DOWNLOAD_CELLPOSE_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a7/a78efe857b2648962ab27574b503765c37be7d880bf2f3e6d3594d3c4816abe5/data'
:         'community.wave.seqera.io/library/python_sopa_cellpose:29454c8abf082ba0' }"

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
