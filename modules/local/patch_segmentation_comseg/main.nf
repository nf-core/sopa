process PATCH_SEGMENTATION_COMSEG {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/cc/cca79776decbf9306c4176032ce799d71e09c82e95cdca85c69878689160d3d1/data'
:         'community.wave.seqera.io/library/python_pip_sopa_comseg:d852d52042b35968' }"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${index}-segmentation_counts.h5ad"), path("${index}-segmentation_polygons.json"), val(n_patches)

    script:
    """
    sopa segmentation comseg ${sdata_path} --patch-index ${index} ${cli_arguments}

    mv ${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_counts.h5ad ${index}-segmentation_counts.h5ad
    mv ${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_polygons.json ${index}-segmentation_polygons.json
    """
}
