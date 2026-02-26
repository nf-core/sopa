process RESOLVE_CELLPOSE {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.11-cellpose'
        : 'docker.io/quentinblampey/sopa:2.1.11-cellpose'}"

    input:
    tuple val(meta), path(sdata_path), path(parquets)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/cellpose_boundaries"
    path "versions.yml"

    script:
    """
    for f in ${parquets}; do
        if [ ! -f "${sdata_path}/.sopa_cache/cellpose_boundaries/\$f" ]; then
            mv "\$f" "${sdata_path}/.sopa_cache/cellpose_boundaries/"
        else
            echo "Skipping \$f: already exists in cache"
        fi
    done

    sopa resolve cellpose ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        cellpose: \$(cellpose --version | grep 'cellpose version:' | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}
