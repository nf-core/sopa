process RESOLVE_STARDIST {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4b/4bd32528c3d37b7f49f1eb47e4c792ae51d3cc38a792cf832dfd07adf44cd68c/data'
:         'community.wave.seqera.io/library/python_pip_sopastardist:df074ee8a42c1e8f' }"

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
