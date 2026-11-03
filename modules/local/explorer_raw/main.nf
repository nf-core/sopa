include { argsExplorerRaw } from '../utils'

process EXPLORER_RAW {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/41/41ba11ed68351d07343e61d1aacaf95b61af20a9bb943e2b3c1829507d970dd7/data'
:         'community.wave.seqera.io/library/python_sopa:56fd765d45ba1fcc' }"

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
