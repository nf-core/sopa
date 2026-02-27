//
// Check input samplesheet and get read channels
//

include { UNTAR as UNTAR_SPACERANGER_INPUT } from "../../../modules/nf-core/untar"
include { UNTAR as UNTAR_DOWNSTREAM_INPUT  } from "../../../modules/nf-core/untar"

workflow INPUT_CHECK {

    take:
    ch_samplesheet // file:    samplesheet read in from --input

    main:

    ch_versions = Channel.empty()

    // Space Ranger analysis: --------------------------------------------------

    // Split channel into tarballed and directory inputs
    ch_spaceranger = ch_samplesheet
        .map { it -> [it, it.fastq_dir] }
        .branch {
            tar: it[1].name.contains(".gz")
            dir: !it[1].name.contains(".gz")
        }

    // Extract tarballed inputs
    UNTAR_SPACERANGER_INPUT (ch_spaceranger.tar )
    ch_versions = ch_versions.mix(UNTAR_SPACERANGER_INPUT.out.versions)

    // Combine extracted and directory inputs into one channel
    ch_spaceranger_combined = UNTAR_SPACERANGER_INPUT.out.untar
        .mix ( ch_spaceranger.dir.map { meta, dir -> [meta, file(dir)] } )
    // Create final meta map and check input existance
    ch_spaceranger_input = ch_spaceranger_combined.map { meta, dir -> create_channel_spaceranger(meta, dir) }

    // Downstream analysis: ----------------------------------------------------
    emit:
    ch_spaceranger_input   // channel: [ val(meta), [ st data ] ]
    ch_versions // channel: [ versions.yml ]

}


// Function to convert a path in `meta` to a file object and return it. If key
// `k` is not contained in `meta` return an empty list which is recognized as
// 'no file' by Nextflow.
def get_file_from_meta(meta, k) {
    def v = meta.get(k)
    return v ? file(v) : []
}

// Function to get list of [ meta, [ fastq_dir, tissue_hires_image, slide, area ]]
def create_channel_spaceranger(meta, fastq_dir) {
    meta["id"] = meta.get("sample")
    def slide = meta.get("slide")
    def area = meta.get("area")

    // Resolve symlinks for local filesystem paths only
    def scheme = fastq_dir.toUri().getScheme()
    if (scheme == null || scheme == 'file') {
        fastq_dir = fastq_dir.toRealPath() // resolve symlink (if applicable)
    }

    def fastq_files = fastq_dir.listFiles().findAll { file ->
        file.name.endsWith('.fastq.gz')
    }

    def manual_alignment = get_file_from_meta(meta, "manual_alignment")
    def slidefile = get_file_from_meta(meta, "slidefile")
    def image = get_file_from_meta(meta, "image")
    def cytaimage = get_file_from_meta(meta, "cytaimage")
    def colorizedimage = get_file_from_meta(meta, "colorizedimage")
    def darkimage = get_file_from_meta(meta, "darkimage")

    if(!fastq_files.size()) {
        error "No `fastq_dir` specified or no samples found in folder."
    }

    // Check for existance of optional files
    def optional_files = [
        'manual_alignment': manual_alignment,
        'slidefile': slidefile,
        'image': image,
        'cytaimage': cytaimage,
        'colorizedimage': colorizedimage,
        'darkimage': darkimage
    ]
    optional_files.each { k, f ->
        if(f && !f.exists()) {
            error "File for `${k}` is specified, but does not exist: ${f}."
        }
    }

    // Check that at least one type of image is specified
    if(!(image || cytaimage || colorizedimage || darkimage)) {
        error "Need to specify at least one of 'image', 'cytaimage', 'colorizedimage', or 'darkimage' in the samplesheet"
    }

    return [meta, fastq_files, image, slide, area, cytaimage, darkimage, colorizedimage, manual_alignment, slidefile]
}
