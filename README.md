
# README
## Introduction
This pipeline is meant to be able to run the PennCNV pipeline inside a docker container, assuming the following input structure (tab separated)
```sh
ID  CHROM   POS sample_id.B Allele Freq sample_id.Log R Ratio
```
This input will be processed into the formated one penncnv requires, so most of the pipeline from this initial processing on can be used by someone merely interested in running the PennCNV pipeline on docker with possibly a few changes in the config file.

## Step 0 - Install docker
Instructions on how to install docker can be found in the [docker website]("https://www.docker.com/"), as well as documentation.

## Step 1 - Clone this repo
```sh
git clone https://github.com/lirialmodobar/penncnv_docker_my_input.git
```

## Step 2 - Process input, get docker image and run docker
Run the process_input_run_docker.sh script.
```sh
cd /path/to/cloned/repo
bash process_input_run_docker.sh 
```
This will generate the processed input in the format shown below (tab separated), as well as get the docker image and run docker.
```sh
 Name   sample_id.B Allele Freq sample_id.Log R Ratio
```
As shown below, the script cuts fields that do not match what the formated input should look like according to the second example on the [PennCNV website](https://penncnv.openbioinformatics.org/en/latest/user-guide/input/). It relies on the existence of an already compiled pfb file where the chromosome coordinates are annotated. Make the necessary changes if you need to cut more fields or if you don't need to cut any. The columns must be named like that, so in case you already have a file with these data, but different column names, change it to the column names above. In my case, it was only necessary to replace "ID" for "Name", so the script does that by using sed (also shown below). Adapt it to change other column names if necessary.
```sh
ls $WD/input > $WD/samples.txt
while read sample; do
       cut -f 1,4,5 $WD/input/$sample > $WD/input/"$sample"_processed
       sed -i 's/ID/Name/g' $WD/input/"$sample"_processed
       rm $WD/input/$sample
done < $WD/samples.txt
rm $WD/samples.txt
```
If you need to make any more changes, adequate them in the script. If you have an Illumina or Metabochip input format and will ask for it to be formated for you by penncnv, you can comment out the code above and leave only the lines below, which are the ones refering to the dirs, files and to docker.
```sh
WD=/path/to/cloned/repo
[ ! -d "$WD/input" ] && mkdir "$WD/input"
[ ! -d "$WD/output" ] && mkdir "$WD/output"
cp /path/to/dir/where/your/input/is/* $WD/input #replace with whatever operation you need to put the samples in the input dir
mv /path/to/pfb/file $WD #replace with whatever operation you need to put the pfb file in the WD
docker pull genomicslab/penncnv
docker run -it -v $WD:/home/user/mounted genomicslab/penncnv
```
**Note:** My original input almost looks like the first example on the website, except for the abscence of one column, but I didn't wanna risk it and already had the pfb file, so I processed the input to look like the 2nd example and used that as my real input. I didn't test if the PennCNV pipeline would work with my input as is. Maybe if it did, I could ask it to compile the pfb file and wouldn't need to have one already. If you have something resembling the first example on the website or my original input, and no pfb file, and want to test if it would work, fell free to do that. I assume that the only thing you should change in the provided config file in order to do that is to opt for compiling a pfb and leaving the pfb path with only the dir for the pfb file, and not the full path to an existing pfb file, but I'm not sure as I didn't test it.

## Step 3 - Running the PennCNV pipeline inside docker
The script in step 2 leaves you inside a docker container. In it, run the following.
```sh
cd /home/mounted/user
bash run_penncnv_docker.sh 
```
The run_penncnv_docker.sh script will call an R script to install the packages that penncnv requires. Since they're not included in the image, this is a mandatory step of the script, make no changes here. It will also run the penncnv pipeline with the config file provided in this repo (it doesn't run the association part - again, you can change this in the config if you'd like) and save a table with the cnv and qs data.
The provided config file looks like this
```sh
pennCNVpath:    /home/user/PennCNV
HMMpath:        /home/user/PennCNV/lib/hhall.hmm 
HMMcreate:      0
PFB:    /home/user/mounted/INPD_c.pfb
CompilePFB:     0
UseGCmod:       0       
InputData:      0
DATA:   /home/user/mounted/input
OUTPUT: /home/user/mounted/output
FormatedPath:   /home/user/mounted/input
Chromosome:     1-22
CNVcall:        1
Cleancall:      1
format: 0
CreateRfile:    1
AssoData:       0
NbCores:        16
Phenotype: no_pheno
```
If you got to this step with the already formated files (them being my processed input or files you had that already matched the second example in the penncnv website) and the pfb, there's no need to change anything here except for the name of the pfb file. Everything else is already standardized, the paths will match if you ran the process_input_run_docker.sh script as is or with the only change being leaving out the loop that processes the input. 
**Note**: The pheno name is necessary even if you're not using a phenotype: it is used to name one of the output dirs and files arent moved properly if not provided. You can change it to whatever name you like. The formated path must be provided even if your formated files are already in the input, because the rest of the PennCNV pipeline looks for the files in the path specified by the formated path, and not the one specified in the input path, so don't leave this out.
In order to be run perfectly, the pipeline must be called inside the penncnv_pipeline dir, so don't change the following lines in the run_penncnv_docker.sh script:
```sh
cd $WD/penncnv_pipeline
bash CNV_detection.sh Config_default.txt
```
The above is the proper way to call it, and the one thing that should change in this entire script is the config file in the cases where formating is necessary, or you need to compile the pfb, or you want to add the association part or something else unrelated to the paths. Information about the config file and how to make these changes for your use can be found in the following file, where you can replace WD as the path to the cloned repo.
```sh
$WD/penncnv_pipeline/PennCNV_pipeline_UserGuide.pdf
```
If you need any more information regarding the PennCNV pipeline, I recommend reading the [PennCNV website](https://penncnv.openbioinformatics.org/en/latest/user-guide/input/).

**Final note:** I'm not sure if QS can be run properly with only one sample, and as far as I can tell, it can't, but I haven't fully tested this hypothesis. The number of samples needed seems to vary: if you run specific combinations of samples from the example, you can even run it with only 2 samples, while in other cases it will require 3 or more, I didn't quite figure this part out.  If you find only NaN in the QS column, the only way I know to fix this is to add more samples, but I don't know how many or which ones. So, basically, I recommend you run all this with only one sample to see if you don't find any errors until you reach the wrong qs column output, not worrying about the NaNs in there. Once you're sure everything up to this point is alright, run it with all your available samples. That would be the safest way I know to prevent this problem.

## Doubts?
Fell free to contact me via email: liriel.almodobar@gmail.com
