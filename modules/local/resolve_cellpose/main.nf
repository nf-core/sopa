process RESOLVE_CELLPOSE {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/sopa:2.2.5--7a8340c1f5d41e34-cellpose'
        : 'community.wave.seqera.io/library/sopa:2.2.5--77a69d04f8380675-cellpose'}"

    input:
    tuple val(meta), path(sdata_path), path(parquets)

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    mkdir -p ${sdata_path}/.sopa_cache/cellpose_boundaries
    for f in ${parquets}; do
        mv "\$f" "${sdata_path}/.sopa_cache/cellpose_boundaries/"
    done

    sopa resolve cellpose ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        cellpose: \$(cellpose --version | grep 'cellpose version:' | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}
