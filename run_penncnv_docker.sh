#!/bin/bash
#inside docker
WD=/home/user/mounted
chmod 777 $WD
Rscript $WD/install_necessary_packages.R
cd $WD/penncnv_pipeline
bash CNV_detection.sh Config_default.txt
mv $WD/save_qs_dataframe.R $WD/output/R
cd $WD/output/R
Rscript $WD/output/R/save_qs_dataframe.R
mv $WD/output/R/save_qs_dataframe.R $WD
