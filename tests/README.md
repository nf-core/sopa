# Tests

The `samplesheet.csv` is technology-agnostic, and uses synthetic data generated when running the pipeline.

## Visium HD specific case

There is an exception for Visium HD data, as it requires to run SpaceRanger before Sopa, and the corresponding samplesheet require more arguments.

The `samplesheet_visium_hd.csv` is made for [this sample](https://www.10xgenomics.com/datasets/visium-hd-cytassist-gene-expression-human-lung-cancer-fixed-frozen). The corresponding data can be downloading via:

```sh
mkdir Visium_HD_Human_Lung_Cancer_Fixed_Frozen
cd Visium_HD_Human_Lung_Cancer_Fixed_Frozen

# Input Files
curl -O https://cf.10xgenomics.com/samples/spatial-exp/3.1.1/Visium_HD_Human_Lung_Cancer_Fixed_Frozen/Visium_HD_Human_Lung_Cancer_Fixed_Frozen_image.tif
curl -O https://cf.10xgenomics.com/samples/spatial-exp/3.1.1/Visium_HD_Human_Lung_Cancer_Fixed_Frozen/Visium_HD_Human_Lung_Cancer_Fixed_Frozen_tissue_image.btf
curl -O https://cf.10xgenomics.com/samples/spatial-exp/3.1.1/Visium_HD_Human_Lung_Cancer_Fixed_Frozen/Visium_HD_Human_Lung_Cancer_Fixed_Frozen_alignment_file.json
curl -O https://s3-us-west-2.amazonaws.com/10x.files/samples/spatial-exp/3.1.1/Visium_HD_Human_Lung_Cancer_Fixed_Frozen/Visium_HD_Human_Lung_Cancer_Fixed_Frozen_fastqs.tar
curl -O https://cf.10xgenomics.com/samples/spatial-exp/3.1.1/Visium_HD_Human_Lung_Cancer_Fixed_Frozen/Visium_HD_Human_Lung_Cancer_Fixed_Frozen_probe_set.csv

# untar FASTQs
tar xvf Visium_HD_Human_Lung_Cancer_Fixed_Frozen_fastqs.tar
```

You can download the official 10X Genomics probe sets [here](https://www.10xgenomics.com/support/software/space-ranger/downloads).

```
https://cf.10xgenomics.com/supp/spatial-exp/probeset/Visium_Human_Transcriptome_Probe_Set_v2.0_GRCh38-2020-A.csv
```
