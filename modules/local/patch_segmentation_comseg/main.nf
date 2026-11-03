process PATCH_SEGMENTATION_COMSEG {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/92/92011ac58047ebc519c2818799a1f9d843b550e02ff96f66725540592ab27c62/data'
:         'community.wave.seqera.io/library/python_pip_sopa_comseg:f767e275ff857065' }"

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
