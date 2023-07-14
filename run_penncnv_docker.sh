#!/bin/bash
#inside docker
WD=/home/user/mounted
chmod 777 $WD
Rscript $WD/install_necessary_packages.R
cd $WD/penncnv_pipeline
bash CNV_detection.sh Config_default.txt
mv $WD/save_qs_dataframe.R $WD/output_teste/R
cd $WD/output_teste/R
Rscript $WD/output_teste/R/save_qs_dataframe.R
mv $WD/save_qs_hist.R $WD/output_teste/R
cd $WD/output_teste/R
Rscript $WD/output_teste/R/save_qs_hist.R
mv $WD/output_teste/R/save_qs_dataframe.R $WD
mv $WD/output_teste/R/save_qs_hist.R $WD
