process RESOLVE_BAYSOR {
    label "process_low"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9f/9f41fa5a39f57afe8cae670456e1e0e849353a8c5efa334f555c93bf1774a323/data'
:         'community.wave.seqera.io/library/python_pip_baysor_sopabaysor:be933088eeb61559' }"

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
