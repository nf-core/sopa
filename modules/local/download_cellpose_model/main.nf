process DOWNLOAD_CELLPOSE_MODEL {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    // CPU image: cellpose v3 | GPU image (task.ext.use_gpu): cellpose v4 + pytorch/CUDA, built from patch_segmentation_cellpose/environment_gpu.yml
    container "${ task.ext.use_gpu
?         'community.wave.seqera.io/library/python_sopa_cellpose_pytorch-gpu_cuda-version:7ca3fb7cbc5a048b'
:         (workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?             'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/22/22d62d6425b70620138ad8764139528c1acaabf6cd06403134c8439caa1c9a31/data'
:             'community.wave.seqera.io/library/python_sopa_cellpose:d098579826bbcf24') }"

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
