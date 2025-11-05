#!/bin/bash

# convert all yaml parameter files in the sopa workflow config directory to nextflow config files
# you have to update the path below to point to your local sopa workflow config directory

find /Users/quentinblampey/dev/sopa/workflow/config -mindepth 2 -maxdepth 2 -type f -name '*.yaml' | while read -r file; do
    parent_dir=$(basename "$(dirname "$file")")
    filename=$(basename "$file")
    name_no_suffix="${filename%.*}"
    output_file="${parent_dir}_${name_no_suffix}.config"

    nextflow run convert.nf -params-file "$file" --output "$output_file"
    echo "$output_file generated."
done
