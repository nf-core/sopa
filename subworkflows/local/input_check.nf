//
// Check input samplesheet and get read channels
//

include { UNTAR as UNTAR_SPACERANGER_INPUT } from "../../modules/nf-core/untar"

workflow INPUT_CHECK {

    take:
    ch_samplesheet

    main:

    ch_versions = Channel.empty()

    // Space Ranger analysis: --------------------------------------------------

    // Split channel into tarballed and directory inputs
    ch_spaceranger = ch_samplesheet
        .map { it -> [it, it.fastq_dir]}
        .branch {
            tar: it[1].name.contains(".tar.gz")
            dir: !it[1].name.contains(".tar.gz")
        }

    // Extract tarballed inputs
    UNTAR_SPACERANGER_INPUT ( ch_spaceranger.tar )
    ch_versions = ch_versions.mix(UNTAR_SPACERANGER_INPUT.out.versions)

    // Combine extracted and directory inputs into one channel
    ch_spaceranger_combined = UNTAR_SPACERANGER_INPUT.out.untar
        .mix ( ch_spaceranger.dir )
        .map { meta, dir -> meta + [fastq_dir: dir] }

    // Create final meta map and check input existance
    ch_spaceranger_input = ch_spaceranger_combined.map { create_channel_spaceranger(it) }

    emit:
    ch_spaceranger_input   // channel: [ val(meta), [ st data ] ]
    versions = ch_versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_dir, tissue_hires_image, slide, area ]]
def create_channel_spaceranger(LinkedHashMap meta) {
    meta["id"] = meta.remove("sample")

    // Convert a path in `meta` to a file object and return it. If `key` is not contained in `meta`
    // return an empty list which is recognized as 'no file' by nextflow.
    def get_file_from_meta = {key ->
        v = meta.remove(key);
        return v ? file(v) : []
    }

    fastq_dir = meta.remove("fastq_dir")
    fastq_files = file("${fastq_dir}/${meta['id']}*.fastq.gz")
    manual_alignment = get_file_from_meta("manual_alignment")
    slidefile = get_file_from_meta("slidefile")
    image = get_file_from_meta("image")
    cytaimage = get_file_from_meta("cytaimage")
    colorizedimage = get_file_from_meta("colorizedimage")
    darkimage = get_file_from_meta("darkimage")

    if(!fastq_files.size()) {
        error "No `fastq_dir` specified or no samples found in folder."
    }

    check_optional_files = ["manual_alignment", "slidefile", "image", "cytaimage", "colorizedimage", "darkimage"]
    for(k in check_optional_files) {
        if(this.binding[k] && !this.binding[k].exists()) {
            error "File for `${k}` is specified, but does not exist: ${this.binding[k]}."
        }
    }
    if(!(image || cytaimage || colorizedimage || darkimage)) {
        error "Need to specify at least one of 'image', 'cytaimage', 'colorizedimage', or 'darkimage' in the samplesheet"
    }

    return [meta, fastq_files, image, cytaimage, darkimage, colorizedimage, manual_alignment, slidefile]
}

