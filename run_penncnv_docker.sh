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
mv $WD/save_qs_hist.R $WD/output #in normal circumstances, this should be $WD/output/R, I didn't complete the pipeline, so my file wasn't moved from output to output/R, so I used it like this, make sure to change it
cd $WD/output  #in normal circunstamces, this should be $WD/output/R, I didn't complete the pipeline, so my file wasn't moved from output to output/R, so I used it like this, make sure to change it
Rscript $WD/output/save_qs_hist.R  #in normal circumstances, this should be $WD/output/R/save_qs_hist.R, I didn't complete the pipeline, so my file wasn't moved from output to output/R, so I used it like this, make sure to change it
mv $WD/output/R/save_qs_dataframe.R $WD
mv $WD/output/save_qs_hist.R $WD  #in normal circumstances, this should be $WD/output/R/save_qs_hist.R, I didn't complete the pipeline, so my file wasn't moved from output to output/R, so I used it like this, make sure to change it
