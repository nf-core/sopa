include { ArgsExplorerRaw } from '../utils'

process EXPLORER_RAW {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.7'
        : 'docker.io/quentinblampey/sopa:2.1.7'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path), path(data_dir)

    output:
    path "${meta.explorer_dir}/morphology*"
    path "${meta.explorer_dir}/transcripts*", optional: true

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${ArgsExplorerRaw(params, data_dir.toString())} --mode "+it" --no-save-h5ad
    """
}
