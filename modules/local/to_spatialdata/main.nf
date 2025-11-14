include { ArgsToSpatialData } from '../utils'

process TO_SPATIALDATA {
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:2.1.9'
        : 'docker.io/quentinblampey/sopa:2.1.9'}"

    input:
    tuple val(meta), path(data_dir), path(fullres_image_file)

    output:
    tuple val(meta), path("${meta.sdata_dir}")
    path "versions.yml"

    script:
    """
    sopa convert ${data_dir} --sdata-path ${meta.sdata_dir} ${ArgsToSpatialData(params, meta, fullres_image_file.toString())}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        spatialdata: \$(python -c "import spatialdata; print(spatialdata.__version__)" 2> /dev/null)
        spatialdata_io: \$(python -c "import spatialdata_io; print(spatialdata_io.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
