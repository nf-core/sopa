#!/bin/bash

# list all the predefined config files, to be added to the nextflow.config profiles section

find . -type f -name '*.config' | while read -r file; do
    filename=$(basename "$file")
    name_no_suffix="${filename%.*}"

    echo "    $name_no_suffix  { includeConfig 'conf/predefined/$name_no_suffix.config' }"
done
