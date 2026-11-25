include { argsExplorerRaw } from '../utils'

process EXPLORER_RAW {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/6c/6cb46ca65a819a047e6b5d31d220aadeb601080397b1ab5128f4f02442618c87/data'
:         'community.wave.seqera.io/library/python_sopa:43202e226371b17f' }"

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
