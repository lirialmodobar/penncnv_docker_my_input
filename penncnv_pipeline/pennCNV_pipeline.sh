#!/bin/bash
# Author: Aurelien Mace
# Pipeline for pennCNV

###################################################### VARIABLES ################################################################################R
# Clear the console
clear;

# Declaration of some default values
echo " "

START=$(date +%s)

PATH_pennCNV="null"
PATH_pfb="null"
PATH_hmm="null"
PATH_GCmod="null"
PATH_pheno="null"
DIR_data="null"
DIR_output="null"
DIR_tp=tmp

illumina=0
CNV_call=0
clean_call=0
create_R_file=0
assoc_data=0
chroms_nb='1-22'
max_proc=4
format=0
CompilePFB=0
use_GCmod=0
int_InputData=0
create_hmm=0
pheno_Type="null"


# Read the default config file. The config file has to be in the same folder as this bash file and has to called Config_default.txt
ifile=Config_default.txt
if [ $# == 1 ]; then
    ifile=$1
fi

PATH_pennCNV=`more $ifile| grep ^pennCNVpath: | awk '{print $2}'`
PATH_hmm=`more $ifile| grep ^HMMpath: | awk '{print $2}'`
create_hmm=`more $ifile| grep ^HMMcreate: | awk '{print $2}'`
PATH_pfb=`more $ifile| grep ^PFB: | awk '{print $2}'`
CompilePFB=`more $ifile| grep ^CompilePFB: | awk '{print $2}'`
PATH_GCmod=`more $ifile| grep ^GCmod: | awk '{print $2}'`
use_GCmod=`more $ifile| grep ^UseGCmod: | awk '{print $2}'`
int_InputData=`more $ifile| grep ^InputData: | awk '{print $2}'`
DIR_data=`more $ifile| grep ^DATA: | awk '{print $2}'`
DIR_output=`more $ifile| grep ^OUTPUT: | awk '{print $2}'`
DIR_Formated=`more $ifile| grep ^FormatedPath: | awk '{print $2}'`
chroms_nb=`more $ifile| grep ^Chromosome: | awk '{print $2}'`
CNV_call=`more $ifile| grep ^CNVcall: | awk '{print $2}'`
clean_call=`more $ifile| grep ^Cleancall: | awk '{print $2}'`
format=`more $ifile| grep ^format: | awk '{print $2}'`
create_R_file=`more $ifile| grep ^CreateRfile: | awk '{print $2}'`
assoc_data=`more $ifile| grep ^AssoData: | awk '{print $2}'`
max_proc=`more $ifile| grep ^NbCores: | awk '{print $2}'`
PATH_pheno=`more $ifile| grep ^PhenoPath: | awk '{print $2}'`
pheno_Type=`more $ifile| grep ^Phenotype: | awk '{print $2}'`

if [ ! $DIR_Formated == '""' ];then illumina=1;fi

# Start the "user interface". The user can modify the default configuration directly through the console
# First the default parameter are displayed to the user, he is then asked to change or not this default configuration

echo " "
echo -e '                   '"PennCNV Pipeline 

Configuration: " $ifile
echo " "
echo -e " 
PennCNV path: Path to the pennCNV folder on your machine, by default  $PATH_pennCNV 
HMM path: Path to the hmm file used for PennCNV, by default  $PATH_hmm 
HMM create: Recalculate or not the HMM transition matrix (for Metabochip), by default  $create_hmm 
PFB path: Path to the pfb file used for PennCNV, by default  $PATH_pfb 
Compile PFB: Compile or not the pfb file, by default  $CompilePFB 
GC model path: Path to the GC model file used for PennCNV, by default  $PATH_GCmod 
Use GC model: Use or not the GC model file, by default  $use_GCmod 
Input data Type: 0 already formated, 1 illumina format, 2 metabochip format, by default  $int_InputData 
DATA path: Path to the data directory, by default  $DIR_data 
OUTPUT path: Path to the data directory where to save the results, by default  $DIR_output 
Path to store formated data: Path of the directory where to save the formated  files, by default  $DIR_Formated 
Chromosome: number of the chromosomes to process, by default  $chroms_nb 
CNV call: run the CNV call (1 for yes or 0 for no), by default  $CNV_call 
Clean run: clean the CNV results (1 for yes or 0 for no), by default  $clean_call 
Format: format the Illumina files (1 for yes or 0 for no), by default  $format 
Create R files: create the R files needed for the association (1 for yes or 0 for no), by default  $create_R_file 
Association Data: calculate the association data (1 for yes or 0 for no), by default  $assoc_data 
CORES: The number of Cores to use for the analysis, by default  $max_proc 
Pheno path: Path to the file containing phenotype information, by default  $PATH_pheno 
Phenotype: Name of the phenotype of interest, by default  $pheno_Type" 
echo -e  " "
echo  -e  "      * * * * * * * * *       " 
echo " "

if [ $DIR_data != "null" ] && [ $DIR_output != "null" ] && [ $PATH_hmm != "null" ]; then
    
# Declaration of some internal variables.
    DIR_temps='tmp_dir'

    FILE_list=list_data.txt
    FILE_list_Raw=list_data_raw.txt
    FILE_list_Formated=list_data_formated.txt
    FILE_list_pfb=list_data_pfb.txt
    FILE_log=ex1.log
    FILE_raw=ex1.rawcnv
    FILE_pfb=out.pfb
    FILE_tmp=tmp.txt
    FILE_goodCNV=goodCNV.good.cnv
    FILE_clean=clean.rawcnv
    FILE_QCsum=QCsum.qcsum

# Check if the list and pfb files already exist, if yes then delete them (not really usefull anymore)
    if [ ! -d "$DIR_output/$DIR_temps" ]; then
        mkdir -p $DIR_output/$DIR_temps
    fi

    if [ -f $DIR_output/$DIR_temps/$FILE_list_Raw ]; then
        rm -f $DIR_output/$DIR_temps/$FILE_list_Raw
    fi

    if [ -f $$DIR_output/$DIR_temps/$FILE_pfb ] && [ PATH_pfb == "null" ]; then
        rm -f $$DIR_output/$DIR_temps/$FILE_pfb
    fi

# Create the list file with the path to all the data
    ls -A -d $DIR_data/* $DIR_data > $DIR_output/$DIR_temps/$FILE_tmp
    tail -n +2 $DIR_output/$DIR_temps/$FILE_tmp > $DIR_output/$DIR_temps/$FILE_list_Raw
    rm $DIR_output/$DIR_temps/$FILE_tmp

    sed "/$FILE_list_Raw/d" $DIR_output/$DIR_temps/$FILE_list_Raw  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Raw
    sed "/$FILE_pfb/d" $DIR_output/$DIR_temps/$FILE_list_Raw  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Raw
    sed "/$FILE_list/d" $DIR_output/$DIR_temps/$FILE_list_Raw  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Raw
    sed "/tmp.txt/d" $DIR_output/$DIR_temps/$FILE_list_Raw  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Raw
    sed "/file_sex/d" $DIR_output/$DIR_temps/$FILE_list_Raw  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Raw


###################################################### NOTHING TO CONVERT ################################################################################
   	if [ $int_InputData == 0 ];then
        echo BLABLA
        #FILE_list=$FILE_list_Raw
        ls -A -d $DIR_Formated/* $DIR_Formated > $DIR_output/$DIR_temps/$FILE_tmp
        tail -n +2 $DIR_output/$DIR_temps/$FILE_tmp > $DIR_output/$DIR_temps/$FILE_list_Formated
        rm $DIR_output/$DIR_temps/$FILE_tmp
        FILE_list=$FILE_list_Formated
    fi

###################################################### CONVERT Illumina or Metabochip #####################################################################

# This if section convert the illumina file to a format that is readable by the different pennCNV function like detect_cnv and compile_pfb
# As it may take time depending of the number of file, this part can be done in parallel.
    if [[ ($int_InputData == 1 || $int_InputData == 2) && $format == 1 ]]; then

		if [ ! -d "$DIR_Formated" ]; then
      		mkdir -p $DIR_Formated
    	fi

            if [ $int_InputData == 1 ];then
                type=Illumina
            elif [ $int_InputData == 2 ];then
                type=Metabochip
            fi
        	echo -e  "*********** Split and format " $type " files ***********" 
       		
            nb_raw=$(wc -l $DIR_output/$DIR_temps/$FILE_list_Raw | awk '{print $1}')

            if [ $nb_raw == 1 ]; then 

                while read line  
                do
                    nice -n 10 $PATH_pennCNV/split_illumina_report.pl -p $DIR_Formated/ $line
                done  < $DIR_output/$DIR_temps/$FILE_list_Raw
            else
                while read line  
                do  
                    if [ $max_proc != 1 ]; then
                        while [ `jobs | wc -l` -ge $max_proc ]
                        do
                            sleep 5
                        done
                        nice -n 10 $PATH_pennCNV/split_illumina_report.pl -p $DIR_Formated/ $line &
                    else
                        $PATH_pennCNV/split_illumina_report.pl -p $DIR_Formated/ $line
                    fi
                done < $DIR_output/$DIR_temps/$FILE_list_Raw

                while [ `jobs | wc -l` -ge 2 ]
                do
                    sleep 5
                done
            fi
                    		
            DIR_data_old=$DIR_data

        ls -A -d $DIR_Formated/* $DIR_Formated > $DIR_output/$DIR_temps/$FILE_tmp
        tail -n +2 $DIR_output/$DIR_temps/$FILE_tmp > $DIR_output/$DIR_temps/$FILE_list
        rm $DIR_output/$DIR_temps/$FILE_tmp

        sed "/$FILE_list/d" $DIR_output/$DIR_temps/$FILE_list  > $DIR_output/$DIR_temps/$FILE_tmp
        mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list
        sed "/$FILE_pfb/d" $DIR_output/$DIR_temps/$FILE_list  > $DIR_output/$DIR_temps/$FILE_tmp
        mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list
        sed "/tmp.txt/d" $DIR_output/$DIR_temps/$FILE_list  > $DIR_output/$DIR_temps/$FILE_tmp
        mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list
        
        DIR_data=$DIR_Formated
    fi
    
INT=$(date +%s)
DIFF=$(( $INT - $START ))
echo -e   "It took $DIFF seconds to format the Illumina files" 

###################################################### COMPILE PFB ################################################################################
if [ $CompilePFB == 1 ]; then
    echo -e  "*********** Create the snppos files for the pfb compilation ***********"
    
    firstrawfile=$(head -1 $DIR_output/$DIR_temps/$FILE_list_Raw)    
    data_line=$(sed -n '/Data/=' $firstrawfile)
    if [ -z $data_line ]; then
        less $firstrawfile | awk -F '\t' -v col1="Name" -v col2="Chr" -v col3='Position' 'NR==1{for(i=1;i<=NF;i++){if($i==col1)c1=i; if ($i==col2)c2=i;if ($i==col3)c3=i}} NR>0{print $c1 "\t" $c2 "\t" $c3}' > $PATH_pfb/snpposfile.txt
    else
        numSNPs=$(head $firstrawfile | tr -d '\r' | grep 'Num SNPs' | awk 'BEGIN {FS="\t"}{print $2}')
        numSamples=$(head $firstrawfile | tr -d '\r' | grep 'Num Samples' | awk 'BEGIN {FS="\t"}{print $2}')
        echo numSNPs = $numSNPs
        echo numSamples = $numSamples
        head -$(($numSNPs+$data_line+1)) $firstrawfile | tail -n +$(($data_line+1)) | awk -F '\t' -v col1="SNP Name" -v col2="Chr" -v col3='Position' 'NR==1{for(i=1;i<=NF;i++){if($i==col1)c1=i; if ($i==col2)c2=i;if ($i==col3)c3=i}} NR>0{print $c1 "\t" $c2 "\t" $c3}' > $PATH_pfb/snpposfile.txt
    fi

    
    echo -e  "*********** Select the 250 random formated files for the pfb compilation ***********"

    ls -A -d $DIR_Formated/* $DIR_Formated > $DIR_output/$DIR_temps/$FILE_tmp
    tail -n +2 $DIR_output/$DIR_temps/$FILE_tmp > $DIR_output/$DIR_temps/$FILE_list_Formated
    rm $DIR_output/$DIR_temps/$FILE_tmp

    sed "/$FILE_list/d" $DIR_output/$DIR_temps/$FILE_list_Formated  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Formated
    sed "/$FILE_pfb/d" $DIR_output/$DIR_temps/$FILE_list_Formated  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Formated
    sed "/tmp.txt/d" $DIR_output/$DIR_temps/$FILE_list_Formated  > $DIR_output/$DIR_temps/$FILE_tmp
    mv $DIR_output/$DIR_temps/$FILE_tmp $DIR_output/$DIR_temps/$FILE_list_Formated

    nb_file=$(wc -l < $DIR_output/$DIR_temps/$FILE_list_Formated)
    for (( i=1;i<=$nb_file;i++ )) do echo $RANDOM $i; done|sort -k1|cut -d" " -f2|head -250 > $DIR_output/$DIR_temps/listInt.txt

    if [ -f "$DIR_output/$DIR_temps/$FILE_list_pfb" ]; then
        rm $DIR_output/$DIR_temps/$FILE_list_pfb
    fi

    while read rand
    do
        line=$(awk "NR==$rand" $DIR_output/$DIR_temps/$FILE_list_Formated)
        echo $line  >> $DIR_output/$DIR_temps/$FILE_list_pfb
    done < $DIR_output/$DIR_temps/listInt.txt

    echo -e  "*********** Run the pfb compilation ***********"
    $PATH_pennCNV/compile_pfb.pl -listfile $DIR_output/$DIR_temps/$FILE_list_pfb -snpposfile $PATH_pfb/snpposfile.txt -output $PATH_pfb/$FILE_pfb
    PATH_pfb=$PATH_pfb/$FILE_pfb

fi

INT2=$(date +%s)
DIFF=$(( $INT2 - $INT ))
echo -e   "It took $DIFF seconds to compile the pfb file" 

###################################################### CREATE HMM FILE FOR METABOCHIP ##########################################################

# Recalculate the transition matrix based on the metabo files, if file not provide by user
if [ $create_hmm == 1 ]; then
    nbLine=$(wc -l $DIR_output/$DIR_temps/$FILE_list | awk '{print $1}')
    tp_list=tp_list.txt
    head -250    $DIR_output/$DIR_temps/$FILE_list > $DIR_output/$DIR_temps/$tp_list
    
    $PATH_pennCNV/detect_cnv.pl -train -listfile $DIR_output/$DIR_temps/$tp_list  -hmmfile $PATH_hmm -pfbfile $PATH_pfb -output $DIR_output/New_hmm
    
    PATH_hmm=$DIR_output/New_hmm.hmm
    
    echo Hello
fi

###################################################### CNV CALL ################################################################################

# depending of the user choice the CNV call can be run or not. 
# If not the user needs to provide the path to the output directory where is stored the ex1.rawcnv file (should later modify the code to let the user provide  the raw file path he wants)
# As it can take lot of time the calculation can be done in parallel. 
    if [ $CNV_call == 1 ];then
        # Run the CNV call
        echo -e  "*********** run the CNV call ***********" 
        
        # In the pfb file, check the presence of cnv probes
        PATH_pfb_noCNV=$(echo $PATH_pfb | awk '{gsub(".pfb$","_nocnv.pfb",$1);print $1}')
        sed -n '/cnv/!p' $PATH_pfb > $PATH_pfb_noCNV
        PATH_pfb=$PATH_pfb_noCNV

        echo $PATH_pfb


        if [ $max_proc == 1 ];then
        	if [ $use_GCmod == 0 ];then
            	$PATH_pennCNV/detect_cnv.pl -test -hmm $PATH_hmm -pfb $PATH_pfb -conf -log $DIR_output/$FILE_log -out $DIR_output/$FILE_raw -list $DIR_output/$DIR_temps/$FILE_list
            else
            	$PATH_pennCNV/detect_cnv.pl -test -hmm $PATH_hmm -pfb $PATH_pfb -conf -log $DIR_output/$FILE_log -out $DIR_output/$FILE_raw -list $DIR_output/$DIR_temps/$FILE_list -gcmodel $PATH_GCmod
            fi
        else
            nb_files=$(cat $DIR_output/$DIR_temps/$FILE_list | wc -l)
            nb_per_Core=`expr $nb_files / $max_proc + 1`
            
            for i in `seq 1 $max_proc`;
            do
                start_val=$(echo "($i - 1)*$nb_per_Core +1" | bc)
                end_val=$(echo "$i*$nb_per_Core" | bc)
                sed -n -e "$start_val","$end_val"p $DIR_output/$DIR_temps/$FILE_list > $DIR_output/$DIR_temps/tmp"$i".txt
                while [ `jobs | wc -l` -ge $max_proc ]
                do
                    sleep 5
                done
                if [ $use_GCmod == 0 ];then
					nice -n 10 $PATH_pennCNV/detect_cnv.pl -test -hmm $PATH_hmm -pfb $PATH_pfb -conf -log $DIR_output/$DIR_temps/tmp_log"$i".log -out $DIR_output/$DIR_temps/tmp_raw"$i".rawcnv -list $DIR_output/$DIR_temps/tmp"$i".txt &
            	else
            		nice -n 10 $PATH_pennCNV/detect_cnv.pl -test -hmm $PATH_hmm -pfb $PATH_pfb -conf -log $DIR_output/$DIR_temps/tmp_log"$i".log -out $DIR_output/$DIR_temps/tmp_raw"$i".rawcnv -list $DIR_output/$DIR_temps/tmp"$i".txt -gcmodel $PATH_GCmod &
            	fi
            done
        fi

        while [ `jobs | wc -l` -ge 2 ]
        do
            sleep 10
        done

        command_cat_raw="cat"
        command_cat_log="cat"
        for i in `seq 1 $max_proc`;
        do
            command_cat_raw="${command_cat_raw} $DIR_output/$DIR_temps/tmp_raw$i.rawcnv"
            command_cat_log="${command_cat_log} $DIR_output/$DIR_temps/tmp_log$i.log"
        done
        eval $command_cat_raw > $DIR_output/$FILE_raw
        eval $command_cat_log > $DIR_output/$FILE_log

        # create a file with the list of SNP present on the platform
        line=$(head -n 1 $DIR_output/$DIR_temps/$FILE_list)
        awk '{ print $1}' $line > $DIR_output/SNPs_list.txt
    fi

INT=$(date +%s)
DIFF=$(( $INT - $INT2 ))
echo -e   "It took $DIFF seconds to run the CNV call" 

###################################################### QC RUN ################################################################################

# According to the user configuration the QC is run or not
# to run the QC the user needs to provide the paath to the output directory where are stored the raw and log files from the CNV call, or he has to run the CNV call in this script
# The QC will return the good CNV for the chromosome selected by the user.
# Some threshold value are used in this QC for the moment they are hardcoded in this script   
    input=$DIR_output/$FILE_raw
    if [ $clean_call == 1 ];then
    	echo -e  "*********** run the clean process ***********" 
    	$PATH_pennCNV/clean_cnv.pl combineseg $DIR_output/$FILE_raw --signalfile $PATH_pfb --output $DIR_output/$FILE_clean
    	input=$DIR_output/$FILE_clean

        $PATH_pennCNV/filter_cnv.pl $input -qclogfile $DIR_output/$FILE_log -qcsumout $DIR_output/$FILE_QCsum -out $DIR_output/$FILE_goodCNV -chroms $chroms_nb
    fi
    
INT2=$(date +%s)
DIFF=$(( $INT2 - $INT ))
echo -e   "It took $DIFF seconds to run the QC" 

###################################################### CALCULATE THE QUALITY SCORE ################################################################################
    mkdir -p $DIR_output/to_upload_$pheno_Type

    pre_folder=""
    if [ $pheno_Type == 'example' ];then
        pre_folder=$(pwd)/
    fi


    if [ $create_R_file == 1 ];then
        echo -e  "*********** Create the R files ***********" 
        mkdir -p $DIR_output/R
        Rscript R_script_convert_raw_cnv.R $pre_folder$DIR_output/$FILE_clean $pre_folder$DIR_output/$FILE_QCsum $pre_folder$DIR_output/R $max_proc
        Rscript R_script_calculate_quality_score.R $pre_folder$DIR_output/R
        Rscript R_script_create_probe_level_data.R $pre_folder$DIR_output/R $pre_folder$PATH_pfb $max_proc

        mv $DIR_output/log_CNV_summary_dataframe.txt $DIR_output/to_upload_$pheno_Type/
        mv $DIR_output/log_Quality_Score_histogram.rdata $DIR_output/to_upload_$pheno_Type/
        mv $DIR_output/log_info_raw.txt $DIR_output/to_upload_$pheno_Type/
    fi

    if [ $assoc_data == 1 ];then
        echo -e  "*********** Calculate the association data ***********" 
        Rscript R_script_calculate_summary_stat.R $pre_folder$DIR_output/R $pre_folder$PATH_pheno $pre_folder$DIR_output $max_proc $pheno_Type

        mv $DIR_output/association_summary_$pheno_Type.txt $DIR_output/to_upload_$pheno_Type/
        mv $DIR_output/association_summary_burden_$pheno_Type.txt $DIR_output/to_upload_$pheno_Type/
        mv $DIR_output/pheno_info_$pheno_Type.txt $DIR_output/to_upload_$pheno_Type/
        mv $DIR_output/log_pheno_histogram_$pheno_Type.rdata $DIR_output/to_upload_$pheno_Type/
    fi

INT=$(date +%s)
DIFF=$(( $INT - $INT2 ))
echo -e   "It took $DIFF seconds to create the R file and to calculate the association data" 

###################################################### END OF THE SCRIPT ################################################################################
    
    if [ -d "$DIR_output/$DIR_temps" ]; then
        rm -r -f $DIR_output/$DIR_temps
	fi

else
    echo "missing input data" 
fi

END=$(date +%s)
DIFF=$(( $END - $START ))
echo -e   "It took $DIFF seconds to run all the script" 
echo ""

