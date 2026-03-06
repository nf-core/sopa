process RESOLVE_STARDIST {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.11-stardist'
        : 'docker.io/quentinblampey/sopa:2.1.11-stardist'}"

    input:
    tuple val(meta), path(sdata_path), path(parquets)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/stardist_boundaries"
    path "versions.yml"

    script:
    """
    for f in ${parquets}; do
        if [ ! -f "${sdata_path}/.sopa_cache/stardist_boundaries/\$f" ]; then
            mv "\$f" "${sdata_path}/.sopa_cache/stardist_boundaries/"
        else
            echo "Skipping \$f: already exists in cache"
        fi
    done

    sopa resolve stardist ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        stardist: \$(python -c "import stardist; print(stardist.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
