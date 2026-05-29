process RESOLVE_BAYSOR {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/python_pip_baysor_sopabaysor:c126d018231f80cf'
        : 'community.wave.seqera.io/library/python_pip_baysor_sopabaysor:47fd540e3f8d27b3'}"

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

        if [ ! -f "${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_counts.loom" ]; then
            mv \$f ${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_counts.loom
        fi
    done

    for f in $polygons; do
        index=\${f%%-*}

        mkdir -p ${sdata_path}/.sopa_cache/transcript_patches/\$index

        if [ ! -f "${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_polygons_2d.json" ]; then
            mv \$f ${sdata_path}/.sopa_cache/transcript_patches/\$index/segmentation_polygons_2d.json
        fi
    done

    sopa resolve baysor ${sdata_path} ${cli_arguments}

    rm -r ${sdata_path}/.sopa_cache/transcript_patches  || true    # cleanup large baysor files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        baysor: \$(baysor --version)
    END_VERSIONS
    """
}
