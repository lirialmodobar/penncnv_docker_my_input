#!/bin/bash
WD=/path/to/your/working/dir #pwd?the one in which you cloned this repo
mkdir $WD/input #add an if not or put it in repo, how to samples
mkdir $WD/output #add an if not or put it in repo
#penncnv_dir here somehow, with the config
#see if script can start here, add obs to put the samples in the input dir
#scp to input dir or cp
ls $WD/input > $WD/samples.txt
while read samples; do
	cut -f n,n,n $WD/$samples > $WD/$samples
done < $WD/samples.txt
rm $WD/samples.txt
docker pull genomicslab/penncnv
docker -it -v $WD:/home/user/mounted genomicslab/penncnv
