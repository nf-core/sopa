process EXPLORER {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:3a64d90551e67cae'
        : 'community.wave.seqera.io/library/python_sopa:63c5d58df2bdd5c5'}"

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
