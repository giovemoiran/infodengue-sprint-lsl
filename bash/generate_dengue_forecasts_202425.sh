#!/bin/bash

# Loop from 1 to 51
for i in {1..51}
do
    echo "Running R script with argument: $i"
    Rscript generate_dengue_forecasts_202425.R $i
    echo "------------------------"
done
