include { argsExplorerRaw } from '../utils'

process EXPLORER_RAW {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:ae2e3bb4a14388f3'
        : 'community.wave.seqera.io/library/python_sopa:835e8c88fff339ab'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path), path(data_dir)

    output:
    path "${meta.explorer_dir}/morphology*"
    path "${meta.explorer_dir}/transcripts*", optional: true

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${argsExplorerRaw(data_dir.toString())} --mode "+it" --no-save-h5ad
    """
}
