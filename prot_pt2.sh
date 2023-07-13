#!/bin/bash
#inside docker
WD=/home/user/mounted
Rscript $WD/install_necessary_packages.R
cd $WD/penncnv_pipeline
bash CNV_detection.sh Config_default.txt
cd $WD/output/R
Rscript $WD/save_qs_dataframe.R
