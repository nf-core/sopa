process PATCH_SEGMENTATION_COMSEG {
    label "process_long"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_pip_sopa_comseg:82adca1dc4b37526'
        : 'community.wave.seqera.io/library/python_pip_sopa_comseg:b037aaf65bc1ff46'}"

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
