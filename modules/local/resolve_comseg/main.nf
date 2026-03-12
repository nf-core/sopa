process RESOLVE_COMSEG {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.11-comseg'
        : 'docker.io/quentinblampey/sopa:2.1.11-comseg'}"

    input:
    tuple val(meta), path(sdata_path), path(counts), path(polygons)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/comseg_boundaries"
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
