# TODO: Add comment
# 
# Author: amarce
###############################################################################

################################################################################################################################################################################################################################
#  Write text for the command windows
################################################################################################################################################################################################################################
print('R - start to calculate the data for later association')

################################################################################################################################################################################################################################
#  Clean workspace
################################################################################################################################################################################################################################
rm(list = ls())

################################################################################################################################################################################################################################
# Load libraries
################################################################################################################################################################################################################################
library(parallel)

################################################################################################################################################################################################################################
# Define function
################################################################################################################################################################################################################################

################################################################################################################################################################################################################################
#  Load the directory path information
################################################################################################################################################################################################################################
args                <- commandArgs(TRUE)
tmp_dir_path        <- args[1]
pheno_path          <- args[2]
results_path        <- args[3]
nb_cores            <- as.numeric(args[4])
pheno_type          <- args[5]

chr_list            <- 1:22

################################################################################################################################################################################################################################
#  Load the phenotypes
################################################################################################################################################################################################################################
pheno_data              <- read.table(file = pheno_path, header = TRUE, sep = '\t',  stringsAsFactors = FALSE)    
idx_no_ID               <- which(pheno_data[,'ID'] == '')
if(length(idx_no_ID) > 0){
    pheno_data <- pheno_data[-idx_no_ID,]
}
idx_no_NA               <- which(is.na(pheno_data[,'ID']))
if(length(idx_no_NA) > 0){
    pheno_data <- pheno_data[-idx_no_NA,]
}
idx_no_Pheno            <- which(is.na(as.numeric(as.character(pheno_data[,'pheno']))))
if(length(idx_no_Pheno) > 0){
    pheno_data <- pheno_data[-idx_no_Pheno,]
}

rownames(pheno_data)    <- as.character(pheno_data[,'ID'])

################################################################################################################################################################################################################################
#  Check the common sample names between pheno and geno
################################################################################################################################################################################################################################
load(file = paste(tmp_dir_path, '/pennCNV_Quality_Score_probe_level_chr', 22, '.rdata', sep = '')) # probe_level_para
sampnames_geno  <- colnames(probe_level_para)
sampnames_pheno <- pheno_data[, 'ID']

sampnames_common    <- as.character(intersect(sampnames_geno, sampnames_pheno))

rm(probe_level_para)

################################################################################################################################################################################################################################
#  Normalize phenotype
################################################################################################################################################################################################################################
pheno_data_norm <-qnorm((rank(as.numeric(as.character(pheno_data[sampnames_common, "pheno"])), na.last = "keep") - 0.5) / sum(!is.na(as.numeric(as.character(pheno_data[sampnames_common, "pheno"])))))

################################################################################################################################################################################################################################
#  Calculate the mean phenotype
################################################################################################################################################################################################################################
pheno_mean      <- mean(pheno_data_norm, na.rm = TRUE)
pheno_square    <- t(pheno_data_norm) %*% pheno_data_norm

################################################################################################################################################################################################################################
#  Count the number of sample taken into account
################################################################################################################################################################################################################################
N <- length(sampnames_common)

################################################################################################################################################################################################################################
#  Calculate data for each probe
################################################################################################################################################################################################################################
print(chr_list)
res_tp    <- mclapply(chr_list, FUN = function(chr, d_pheno_data, d_tmp_dir_path, d_sampnames_common){
#res_tp    <- lapply(chr_list, FUN = function(chr, d_pheno_data, d_tmp_dir_path, d_sampnames_common){
    load(file = paste(d_tmp_dir_path, '/pennCNV_Quality_Score_probe_level_chr', chr, '.rdata', sep = '')) # probe_level_para

    probe_level_para    <- probe_level_para[, d_sampnames_common]

    dup_count           <- rowSums(probe_level_para > 0)
    del_count           <- rowSums(probe_level_para < 0)

    dup_count08         <- rowSums(probe_level_para > 0.8)
    del_count08         <- rowSums(probe_level_para < -0.8)
    dup_count05         <- rowSums(probe_level_para > 0.5)
    del_count05         <- rowSums(probe_level_para < -0.5)
    dup_count03         <- rowSums(probe_level_para > 0.3)
    del_count03         <- rowSums(probe_level_para < -0.3)

    probe_level_para_del                                    <- probe_level_para
    probe_level_para_del[which(probe_level_para_del > 0)]   <- 0
    probe_level_para_dup                                    <- probe_level_para
    probe_level_para_dup[which(probe_level_para_dup < 0)]   <- 0

    # Geno val
    geno_mean           <- rowMeans(probe_level_para)
    geno_square         <- rowSums(probe_level_para^2)
    geno_mean_del       <- rowMeans(probe_level_para_del)
    geno_square_del     <- rowSums(probe_level_para_del^2)
    geno_mean_dup       <- rowMeans(probe_level_para_dup)
    geno_square_dup     <- rowSums(probe_level_para_dup^2)

    # Geno val
    pheno_geno          <- probe_level_para %*% d_pheno_data
    pheno_geno_del      <- probe_level_para_del %*% d_pheno_data
    pheno_geno_dup      <- probe_level_para_dup %*% d_pheno_data

    geno_abs_sum        <- colSums(abs(probe_level_para))
    geno_abs_sum_del    <- colSums(abs(probe_level_para_del))
    geno_abs_sum_dup    <- colSums(abs(probe_level_para_dup))

    geno_geno           <- rowSums(probe_level_para[-nrow(probe_level_para), ]          * probe_level_para[-1, ])
    geno_geno_del       <- rowSums(probe_level_para_del[-nrow(probe_level_para_del), ]  * probe_level_para_del[-1, ])
    geno_geno_dup       <- rowSums(probe_level_para_dup[-nrow(probe_level_para_dup), ]  * probe_level_para_dup[-1, ])

    data_to_return_1                <- cbind(chr = rep(chr, nrow(probe_level_para)), probe = rownames(probe_level_para), geno_mean = geno_mean, geno_mean_del = geno_mean_del, geno_mean_dup = geno_mean_dup, geno_square = geno_square, geno_square_del = geno_square_del, geno_square_dup = geno_square_dup, pheno_geno = pheno_geno, pheno_geno_del = pheno_geno_del, pheno_geno_dup = pheno_geno_dup, dup_count = dup_count, del_count = del_count, geno_geno = c(geno_geno, NA), geno_geno_del = c(geno_geno_del, NA), geno_geno_dup = c(geno_geno_dup, NA), dup_count03 = dup_count03, dup_count05 = dup_count05, dup_count08 = dup_count08, del_count03 = del_count03, del_count05 = del_count05, del_count08 = del_count08)
    colnames(data_to_return_1)      <- c('chr', 'probe', 'geno_mean', 'geno_mean_del', 'geno_mean_dup', 'geno_square', 'geno_square_del', 'geno_square_dup', 'pheno_geno', 'pheno_geno_del', 'pheno_geno_dup', 'dup_count', 'del_count', 'geno_geno', 'geno_geno_del', 'geno_geno_dup', 'dup_count03', 'dup_count05', 'dup_count08', 'del_count03', 'del_count05', 'del_count08')
    data_to_return                  <- list(data_to_return_1 = data_to_return_1, geno_abs_sum = rbind(all = geno_abs_sum, del = geno_abs_sum_del, dup = geno_abs_sum_dup))
    return(data_to_return)

}, d_pheno_data = pheno_data_norm, d_tmp_dir_path = tmp_dir_path, d_sampnames_common = sampnames_common, mc.cores = nb_cores, mc.preschedule = FALSE)

res                 <- NULL
sample_geno_burden  <- rep(0, N)
for(chr in chr_list){
    res                 <- rbind(res, res_tp[[chr]][[1]])
    sample_geno_burden  <- sample_geno_burden + res_tp[[chr]][[2]]
}
rm(res_tp)

################################################################################################################################################################################################################################
#  Create output variable
################################################################################################################################################################################################################################
pheno_info <- t(as.matrix(c(N = N, pheno_mean = pheno_mean, pheno_square = pheno_square), nrow = 1))

################################################################################################################################################################################################################################
#  Save the data in a text file
################################################################################################################################################################################################################################
write.table(res         , file = paste(results_path, '/association_summary_'    , pheno_type,'.txt', sep = '') , sep = '\t', quote = FALSE, row.names = FALSE, col.names = TRUE)
write.table(pheno_info  , file = paste(results_path, '/pheno_info_'             , pheno_type,'.txt', sep = '') , sep = '\t', quote = FALSE, row.names = FALSE, col.names = TRUE)

pheno_histogram     <- hist(pheno_data_norm, breaks = 20, plot = FALSE)
path_pheno_log_tp   <- strsplit(tmp_dir_path, '/')[[1]]
path_pheno_log      <- paste(path_pheno_log_tp[-length(path_pheno_log_tp)], collapse = '/')
save(pheno_histogram, file = paste(path_pheno_log, '/log_pheno_histogram_', pheno_type,'.rdata', sep = ''))

################################################################################################################################################################################################################################
#  Calculate summary stat for burden test
################################################################################################################################################################################################################################
geno_burden_mean    <- rowMeans(sample_geno_burden)
geno_burden_square  <- rowSums(sample_geno_burden ^ 2)
pheno_geno_burden   <- rowSums(sample_geno_burden * matrix(rep(pheno_data_norm, nrow(sample_geno_burden)), nrow = nrow(sample_geno_burden), byrow = TRUE)) 

burden_res  <- as.matrix(cbind(geno_burden_mean = geno_burden_mean, geno_burden_square = geno_burden_square, pheno_geno_burden = pheno_geno_burden), nrow = nrow(sample_geno_burden))
write.table(burden_res  , file = paste(results_path, '/association_summary_burden_', pheno_type,'.txt', sep = '') , sep = '\t', quote = FALSE, row.names = FALSE, col.names = TRUE)

################################################################################################################################################################################################################################
#  Write text for the command windows
################################################################################################################################################################################################################################
print('R - finish to calculate the data for later association')










