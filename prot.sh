#!/bin/bash
WD=/path/to/cloned/repo
mkdir $WD/input #if it doesnt exist
mkdir $WD/output #if it doesnt exist
#scp to input dir or cp, whichever way you need to put the samples in the input folder
ls $WD/input > $WD/samples.txt
while read samples; do
	cut -f 1,4,5 $WD/$samples | sed -i 's/ID/Name/g' > $WD/$samples
done < $WD/samples.txt
rm $WD/samples.txt
docker pull genomicslab/penncnv
docker -it -v $WD:/home/user/mounted genomicslab/penncnv
