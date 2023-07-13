#!/bin/bash
# Author: Aurelien Mace
# Pipeline for pennCNV


ifile=Config_default.txt
if [ $# == 1 ]; then
    ifile=$1
fi

DIR_output=`more $ifile| grep ^OUTPUT: | awk '{print $2}'`
pheno_Type=`more $ifile| grep ^Phenotype: | awk '{print $2}'`

mkdir -p $DIR_output/to_upload_$pheno_Type

./pennCNV_pipeline.sh $ifile 2>&1 | tee $DIR_output/log_pipeline_$pheno_Type.log

mv $DIR_output/log_pipeline_$pheno_Type.log $DIR_output/to_upload_$pheno_Type/


