process EXPLORER {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/70/707825bb6afa202806406063665a361b2a4a2fc6d6f802132359407408826ffe/data'
:         'community.wave.seqera.io/library/python_sopa:54a97bc5a187152d' }"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    path "${meta.explorer_dir}/experiment.xenium"
    path "${meta.explorer_dir}/analysis.zarr.zip"
    path "${meta.explorer_dir}/cell_feature_matrix.zarr.zip"
    path "${meta.explorer_dir}/adata.h5ad"
    path "${meta.explorer_dir}/cells.zarr.zip"

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${cli_arguments} --mode "-it"
    """
}
