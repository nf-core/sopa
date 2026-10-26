include { argsToSpatialData } from '../utils'

process TO_SPATIALDATA {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b860a96dd8283cde996464a8aaee98a1094be86a6285193f2919c8a59a106a99/data'
:         'community.wave.seqera.io/library/python_sopa:e01bf52e9d748218' }"

    input:
    tuple val(meta), path(data_dir), path(fullres_image_file)

    output:
    tuple val(meta), path("${meta.sdata_dir}")
    path "versions.yml"

    script:
    """
    sopa convert ${data_dir} --sdata-path ${meta.sdata_dir} ${argsToSpatialData(meta, fullres_image_file.toString())}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        spatialdata: \$(python -c "import spatialdata; print(spatialdata.__version__)" 2> /dev/null)
        spatialdata_io: \$(python -c "import spatialdata_io; print(spatialdata_io.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
