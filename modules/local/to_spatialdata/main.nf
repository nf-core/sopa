include { argsToSpatialData } from '../utils'

process TO_SPATIALDATA {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/sopa:2.2.5--7a8340c1f5d41e34'
        : 'community.wave.seqera.io/library/sopa:2.2.5--77a69d04f8380675'}"

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
