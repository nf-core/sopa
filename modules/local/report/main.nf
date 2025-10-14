process REPORT {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.5'
        : 'docker.io/quentinblampey/sopa:2.1.5'}"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(sdata_path)

    output:
    path sdata_path
    path "${meta.explorer_dir}/analysis_summary.html"

    script:
    """
    mkdir -p ${meta.explorer_dir}

    sopa report ${sdata_path} ${meta.explorer_dir}/analysis_summary.html

    rm -r ${sdata_path}/.sopa_cache || true # clean up cache if existing
    """
}
