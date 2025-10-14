process EXPLORER_RAW {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.5'
        : 'docker.io/quentinblampey/sopa:2.1.5'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path), path(data_dir)
    val cli_arguments

    output:
    path "${meta.explorer_dir}/morphology*"
    path "${meta.explorer_dir}/transcripts*", optional: true

    script:
    """
    sopa explorer write ${sdata_path} --output-path ${meta.explorer_dir} ${cli_arguments} --mode "+it" --no-save-h5ad
    """
}
