process RESOLVE_STARDIST {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_pip_sopastardist:90d5386bb9759378'
        : 'community.wave.seqera.io/library/python_pip_sopastardist:daeb0671bfa69bc7'}"

    input:
    tuple val(meta), path(sdata_path), path(parquets)

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    mkdir -p ${sdata_path}/.sopa_cache/stardist_boundaries
    for f in ${parquets}; do
        mv "\$f" "${sdata_path}/.sopa_cache/stardist_boundaries/"
    done

    sopa resolve stardist ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        stardist: \$(python -c "import stardist; print(stardist.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
