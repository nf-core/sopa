process PATCH_SEGMENTATION_COMSEG {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/74/7452b571c9bedf0d0c6c877f0f98dc1a67ae32180b9c258e58066e927361393e/data'
:         'community.wave.seqera.io/library/python_pip_sopa_comseg:950185f8fb335433' }"

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
