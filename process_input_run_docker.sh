#!/bin/bash
WD=/mnt/genetica_1/liriel/juliathon/penncnv_docker_my_input #/path/to/cloned/repo
[ ! -d "$WD/input" ] && mkdir "$WD/input"
[ ! -d "$WD/output" ] && mkdir "$WD/output"
cp /mnt/genetica_1/liriel/juliathon/julia_data/* $WD/input #replace with whatever operation you need to put the samples in the input dir
mv /mnt/genetica_1/liriel/juliathon/INPD_c.pfb $WD #replace with whatever operation you need to put the pfb file in the WD dir
ls $WD/input > $WD/samples.txt
while read sample; do
       cut -f 1,4,5 $WD/input/$sample > $WD/input/"$sample"_processed
       sed -i 's/ID/Name/g' $WD/input/"$sample"_processed
       rm $WD/input/$sample
done < $WD/samples.txt
rm $WD/samples.txt
docker pull genomicslab/penncnv
docker run -it -v $WD:/home/user/mounted genomicslab/penncnv
