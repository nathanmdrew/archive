library(dplyr); library(readxl)

# read-in the manually created spreadsheet
d <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/OEBs.xlsx",
           sheet="All",
           col_names=T)


# get list of inflammation endpoints for filter
endpt <- distinct(d, Endpoint)
endpt$keep <- c(1,0,1,1,0,0,1,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1)
endpt_keep <- endpt %>% filter(keep==1) %>% select(Endpoint)
endpt_keep2 <- pull(endpt_keep, Endpoint)

# keep non-NTP references
ref <- distinct(d,Reference)

vars <- names(d)

# Filter for inflammation OEB results
d2 <- d %>% dplyr::filter(is.na(.data[[vars[[2]]]])) %>% #Exclude? flag
            dplyr::filter(is.na(.data[[vars[[34]]]])) %>% #No band flag
            dplyr::filter(Organ != "Liver") %>%
            dplyr::filter(Reference != "NTP") %>%
            dplyr::filter(Endpoint %in% endpt_keep2)

#a copy of the pivot table rows for QC
# f <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/OEBs_filtered.xlsx",
#                 sheet=1,
#                 col_names=T)
# 
# 
# d2.row <- pull(d2, rownum)
# 
# qc.rows <- f %>% filter(!rownum %in% d2.row)
#matches           


table.d3 <- d2 %>% select(Material, Scale, `Material Type`, Duration, Species, Strain, Sex, Reference, `Most Stringent Band`) %>%
                   arrange(Material, Scale, `Material Type`)

#table(table.d3$Scale)

saveRDS(table.d3, file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/tableD3 20240708.RDS")
write.csv(table.d3, file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/tableD3 20240708.csv")

