process REPORT {
    label "process_medium"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_sopa:b18f7051c113391d'
        : 'community.wave.seqera.io/library/python_sopa:271022a587d06a6e'}"

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
