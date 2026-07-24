process RESOLVE_COMSEG {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/cc/cca79776decbf9306c4176032ce799d71e09c82e95cdca85c69878689160d3d1/data'
:         'community.wave.seqera.io/library/python_pip_sopa_comseg:d852d52042b35968' }"

    input:
    tuple val(meta), path(sdata_path), path(counts), path(polygons)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    for f in $counts; do
        index=\${f%%-*}

        mkdir -p ${sdata_path}/.sopa_cache/transcript_patches/\$index

        if [ ! -f "${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_counts.h5ad" ]; then
            mv \$f ${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_counts.h5ad
        fi
    done

    for f in $polygons; do
        index=\${f%%-*}

        mkdir -p ${sdata_path}/.sopa_cache/transcript_patches/\$index

        if [ ! -f "${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_polygons.json" ]; then
            mv \$f ${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_polygons.json
        fi
    done

    sopa resolve comseg ${sdata_path} ${cli_arguments}

    rm -r ${sdata_path}/.sopa_cache/transcript_patches  || true    # cleanup large comseg files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        comseg: \$(python -c "import comseg; print(comseg.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
