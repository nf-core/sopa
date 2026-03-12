process RESOLVE_BAYSOR {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.11-baysor'
        : 'docker.io/quentinblampey/sopa:2.1.11-baysor'}"

    input:
    tuple val(meta), path(sdata_path), path(counts), path(polygons)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/baysor_boundaries"
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
