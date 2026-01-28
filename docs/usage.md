# nf-core/sopa: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/sopa/usage](https://nf-co.re/sopa/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 2 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Main technologies

For all technologies supported by Sopa, the samplesheet lists the `data_path` to each sample data directory, and optionally a `sample` column to choose the name of the output directories.

> [!NOTE]
> For **Visium HD only**, the samplesheet is different, please refer to the next section instead.

The concerned technologies are: `xenium`, `merscope`, `cosmx`, `molecular_cartography`, `macsima`, `phenocycler`, `ome_tif`, and `hyperion`.

| Column      | Description                                                                                                                                                                                                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data_path` | **Path to the raw data**; a directory containing the output of the machine with the data of a single sample or region. Typically, this directory contains one or multiple image(s), and a transcript file (`.csv` or `.parquet`) for transcriptomics technologies. See more details below. _Required_ |
| `sample`    | **Custom sample ID (optional)**; designates the sample ID; must be unique for each patient. It will be used in the output directories names: `{sample}.zarr` and `{sample}.explorer`. _Optional, Default: the basename of `data_path` (i.e., the last directory component of `data_path`)_            |

Here is a samplesheet example for two samples:

`samplesheet.csv`:

```csv title="samplesheet.csv"
sample,data_path
SAMPLE1,/path/to/one/merscope_directory
SAMPLE2,/path/to/another/merscope_directory
```

#### `data_path` directory content

| Technology            | `data_path` directory content                                                                                                                                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| xenium                | `transcripts.parquet`, `experiment.xenium`, and `morphology_focus.ome.tif` or a morphology directory.                                                                                                                  |
| merscope              | `detected_transcripts.csv`, all the images under the `images` subdirectory, and `images/micron_to_mosaic_pixel_transform.csv` (affine transformation)                                                                  |
| cosmx                 | `*_fov_positions_file.csv` or `*_fov_positions_file.csv.gz` (FOV locations),`Morphology2D` (directory with all the FOVs morphology images), and `*_tx_file.csv.gz` or `*_tx_file.csv` (transcripts location and names) |
| molecular_cartography | Multiple `.tiff` images and `_results.txt` files.                                                                                                                                                                      |
| macsima               | Multiple `.tif` images                                                                                                                                                                                                 |
| phenocycler           | For this technology, `data_path` is not a directory, but a `.qptiff` or `.tif` file containing all channels for a given sample.                                                                                        |
| hyperion              | Multiple `.tif` images                                                                                                                                                                                                 |
| ome_tif               | Generic reader for which `data_path` is not a directory, but a `.ome.tif` file containing all channels for a given sample.                                                                                             |

### Visium HD

Some extra columns need to be provided specifically for Visium HD. This is because we need to run [Space Ranger](https://www.10xgenomics.com/support/software/space-ranger/latest) before running Sopa. Note that the `image` is the full-resolution microscopy image (not the cytassist image) and is **required** by Sopa as we'll run cell segmentation on the H&E full-resolution slide. For more details, see the [`spaceranger-count` arguments](https://nf-co.re/modules/spaceranger_count).

| Column             | Description                                                                                                                                                                                                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`           | **Sample ID name**; designates the sample ID; must be unique for each slide. It will be used in the output directories names: `{sample}.zarr` and `{sample}.explorer`. _Required_                                                                                                      |
| `id`               | Name of the slide to be provided to Space Ranger. The sample can be deduced from the fastq*dir, as the fastq files should have the format `<SAMPLE>\_S<N>\_L001*<XX>_001.fastq.gz`(where N is a number, and XX can be R1, R2, I1 or I2). By default, use the`sample` name. \_Optional_ |
| `fastq_dir`        | Path to directory where the sample FASTQ files are stored. May be a `.tar.gz` file instead of a directory. _Required_                                                                                                                                                                  |
| `image`            | Brightfield microscopy image. _Required_                                                                                                                                                                                                                                               |
| `cytaimage`        | Brightfield tissue image captured with Cytassist device. _Required_                                                                                                                                                                                                                    |
| `slide`            | The Visium slide ID used for the sequencing. _Required_                                                                                                                                                                                                                                |
| `area`             | Which slide area contains the tissue sample. _Required_                                                                                                                                                                                                                                |
| `manual_alignment` | Path to the manual alignment file. _Optional_                                                                                                                                                                                                                                          |
| `slidefile`        | Slide specification as JSON. Overrides `slide` and `area` if specified. _Optional_                                                                                                                                                                                                     |
| `colorizedimage`   | A colour composite of one or more fluorescence image channels saved as a single-page, single-file colour TIFF or JPEG. _Optional_                                                                                                                                                      |
| `darkimage`        | Dark background fluorescence microscopy image. _Optional_                                                                                                                                                                                                                              |

Here is a samplesheet example for one sample:

```csv title="samplesheet.csv"
sample,fastq_dir,image,cytaimage,slide,area
Visium_HD_Human_Lung_Cancer_Fixed_Frozen,Visium_HD_Human_Lung_Cancer_Fixed_Frozen_fastqs,Visium_HD_Human_Lung_Cancer_Fixed_Frozen_tissue_image.btf,Visium_HD_Human_Lung_Cancer_Fixed_Frozen_image.tif,H1-TY834G7,D1
```

This samplesheet was made for [this public sample](https://www.10xgenomics.com/datasets/visium-hd-cytassist-gene-expression-human-lung-cancer-fixed-frozen) (download all the "Input files" and untar the `fastq` zip file to test it).

## Sopa parameters

You'll also need to choose some Sopa parameters to decide which reader/segmentation tool to use. To do that, provide an existing `-profile` containing all the dedicated Sopa parameters, depending on your technology:

- `xenium_proseg`
  - A profile with Sopa parameters to run Proseg on Xenium data
- `xenium_baysor`
  - A profile with Sopa parameters to run Baysor on Xenium data
- `xenium_baysor_prior_small_cells`
  - Same as above, but with a smaller Baysor scale for the cell diameter
- `xenium_baysor_prior`
  - A profile with Sopa parameters to run Baysor on Xenium data with the 10X Genomics segmentation as a prior
- `xenium_cellpose_baysor`
  - A profile with Sopa parameters to run Cellpose as a prior for Baysor on Xenium data
- `xenium_cellpose`
  - A profile with Sopa parameters to run Cellpose on Xenium data
- `merscope_baysor_cellpose`
  - A profile with Sopa parameters to run Cellpose as a prior for Baysor on MERSCOPE data
- `merscope_baysor_vizgen`
  - A profile with Sopa parameters to run Baysor on MERSCOPE data with the Vizgen segmentation as a prior
- `merscope_proseg`
  - A profile with Sopa parameters to run Proseg on MERSCOPE data
- `merscope_cellpose`
  - A profile with Sopa parameters to run Cellpose on MERSCOPE data
- `cosmx_cellpose`
  - A profile with Sopa parameters to run Cellpose on CosMx data
- `cosmx_proseg`
  - A profile with Sopa parameters to run Proseg on CosMx data
- `cosmx_baysor`
  - A profile with Sopa parameters to run Baysor on Xenium data
- `cosmx_cellpose_baysor`
  - A profile with Sopa parameters to run Cellpose as a prior for Baysor on CosMx data
- `visium_hd_stardist`
  - A profile with Sopa parameters to run Stardist on Visium HD data
- `visium_hd_proseg`
  - A profile with Sopa parameters to run Proseg on Visium HD data (it will use the 10X Genomics segmentation as a prior)
- `visium_hd_stardist_proseg`
  - A profile with Sopa parameters to run Stardist on Visium HD data as a prior for Proseg
- `phenocycler_base_10X`
  - A profile with Sopa parameters to run Cellpose on Phenocycler data at 10X resolution
- `phenocycler_base_20X`
  - A profile with Sopa parameters to run Cellpose on Phenocycler data at 20X resolution
- `phenocycler_base_40X`
  - A profile with Sopa parameters to run Cellpose on Phenocycler data at 40X resolution
- `hyperion_base`
  - A profile with Sopa parameters to run Cellpose on Hyperion data
- `macsima_base`
  - A profile with Sopa parameters to run Cellpose on MACSima data

These profiles contain the backbone of the pipeline, i.e. which technology to use and how to process the segmentation. For more customization, you can provide [other Sopa parameters](https://nf-co.re/sopa/dev/parameters/) via the command line, for instance `--use_scanpy_preprocessing true` if you want to have a UMAP and a Leiden clustering on your output AnnData object.

## Running the pipeline

Once you have defined (i) your samplesheet and (ii) your Sopa parameters (denoted below as `<TECHNOLOGY_PROFILE>`), you'll be able to run `nf-core/sopa`. The typical command for running the pipeline is as follows.

```bash
nextflow run nf-core/sopa --input ./samplesheet.csv --outdir ./results  -profile docker,<TECHNOLOGY_PROFILE>
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

> [!NOTE]
> For Visium HD data, you may also need to provide a `--spaceranger_probeset` argument with an official 10X Genomics probe set (see [here](https://www.10xgenomics.com/support/software/space-ranger/downloads)). For instance, you can use:
>
> ```bash
> --spaceranger_probeset https://cf.10xgenomics.com/supp/spatial-exp/probeset/Visium_Human_Transcriptome_Probe_Set_v2.0_GRCh38-2020-A.csv
> ```

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/sopa -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/sopa
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/sopa releases page](https://github.com/nf-core/sopa/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.
- Some Sopa-specific profiles are listed in the above [Sopa parameters](#sopa-parameters) section.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
