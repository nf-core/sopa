process RESOLVE_CELLPOSE {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    // CPU image: cellpose v3 | GPU image (task.ext.use_gpu): cellpose v4 + pytorch/CUDA, built from patch_segmentation_cellpose/environment_gpu.yml
    container "${ task.ext.use_gpu
?         (workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?             'TODO_SINGULARITY_GPU_IMAGE_URL'
:             'TODO_DOCKER_GPU_IMAGE')
:         (workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?             'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/22/22d62d6425b70620138ad8764139528c1acaabf6cd06403134c8439caa1c9a31/data'
:             'community.wave.seqera.io/library/python_sopa_cellpose:d098579826bbcf24') }"

    input:
    tuple val(meta), path(sdata_path), path(parquets)

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    mkdir -p ${sdata_path}/.sopa_cache/cellpose_boundaries
    for f in ${parquets}; do
        mv "\$f" "${sdata_path}/.sopa_cache/cellpose_boundaries/"
    done

    sopa resolve cellpose ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        cellpose: \$(cellpose --version | grep 'cellpose version:' | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}
