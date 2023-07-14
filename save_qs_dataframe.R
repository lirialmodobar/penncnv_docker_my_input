data <- get(load("cnv_data_global.rdata"))
write.table(data, "cnv_data_and_qs.txt", row.names = FALSE, quote = FALSE)
