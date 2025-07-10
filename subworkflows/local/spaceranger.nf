//
// Raw data processing with Space Ranger
//

include { UNTAR as SPACERANGER_UNTAR_REFERENCE } from "../../modules/nf-core/untar"
include { UNTAR as UNTAR_SPACERANGER_INPUT } from "../../modules/nf-core/untar"
include { SPACERANGER_COUNT } from '../../modules/nf-core/spaceranger/count'

workflow SPACERANGER {
    take:
    ch_samplesheet

    main:

    ch_versions = Channel.empty()

    // Space Ranger analysis: --------------------------------------------------

    // Split channel into tarballed and directory inputs
    ch_spaceranger = ch_samplesheet
        .map { it -> [it, it.fastq_dir] }
        .branch {
            tar: it[1].name.contains(".tar.gz")
            dir: !it[1].name.contains(".tar.gz")
        }

    // Extract tarballed inputs
    UNTAR_SPACERANGER_INPUT(ch_spaceranger.tar)
    ch_versions = ch_versions.mix(UNTAR_SPACERANGER_INPUT.out.versions)

    // Combine extracted and directory inputs into one channel
    ch_spaceranger_combined = UNTAR_SPACERANGER_INPUT.out.untar
        .mix(ch_spaceranger.dir)
        .map { meta, dir -> meta + [fastq_dir: dir] }

    // Create final meta map and check input existance
    ch_spaceranger_input = ch_spaceranger_combined.map { create_channel_spaceranger(it) }


    //
    // Reference files
    //
    ch_reference = Channel.empty()
    if (params.spaceranger_reference ==~ /.*\.tar\.gz$/) {
        ref_file = file(params.spaceranger_reference)
        SPACERANGER_UNTAR_REFERENCE(
            [
                [id: "reference"],
                ref_file,
            ]
        )
        ch_reference = SPACERANGER_UNTAR_REFERENCE.out.untar.map { _meta, ref -> ref }
        ch_versions = ch_versions.mix(SPACERANGER_UNTAR_REFERENCE.out.versions)
    }
    else {
        ch_reference = file(params.spaceranger_reference, type: "dir", checkIfExists: true)
    }

    //
    // Optional: probe set
    //
    ch_probeset = Channel.empty()
    if (params.spaceranger_probeset) {
        ch_probeset = file(params.spaceranger_probeset, checkIfExists: true)
    }
    else {
        ch_probeset = []
    }

    //
    // Run Space Ranger count
    //
    SPACERANGER_COUNT(
        ch_spaceranger_input,
        ch_reference,
        ch_probeset,
    )

    ch_versions = ch_versions.mix(SPACERANGER_COUNT.out.versions.first())

    emit:
    sr_dir = SPACERANGER_COUNT.out.outs
    versions = ch_versions // channel: [ versions.yml ]
}


// Function to get list of [ meta, [ fastq_dir, tissue_hires_image, slide, area ]]
def create_channel_spaceranger(LinkedHashMap meta) {
    // Convert a path in `meta` to a file object and return it. If `key` is not contained in `meta`
    // return an empty list which is recognized as 'no file' by nextflow.
    def get_file_from_meta = { key ->
        def v = meta[key]
        return v ? file(v) : []
    }

    def fastq_dir = meta.remove("fastq_dir")
    def fastq_files = file("${fastq_dir}/${meta['id']}*.fastq.gz")
    def manual_alignment = get_file_from_meta("manual_alignment")
    def slidefile = get_file_from_meta("slidefile")
    def image = get_file_from_meta("image")
    def cytaimage = get_file_from_meta("cytaimage")
    def colorizedimage = get_file_from_meta("colorizedimage")
    def darkimage = get_file_from_meta("darkimage")

    if (!fastq_files.size()) {
        error("No `fastq_dir` specified or no samples found in folder.")
    }

    def check_optional_files = [["manual_alignment", manual_alignment], ["slidefile", slidefile], ["image", image], ["cytaimage", cytaimage], ["colorizedimage", colorizedimage], ["darkimage", darkimage]]
    check_optional_files.each { name, value ->
        if (value && !file(value).exists()) {
            error("File for `${name}` is specified, but does not exist: ${value}.")
        }
    }
    if (!(image || cytaimage || colorizedimage || darkimage)) {
        error("Need to specify at least one of 'image', 'cytaimage', 'colorizedimage', or 'darkimage' in the samplesheet")
    }

    return [meta, fastq_files, image, cytaimage, darkimage, colorizedimage, manual_alignment, slidefile]
}
