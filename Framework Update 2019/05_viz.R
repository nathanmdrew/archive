library(dplyr)
library(readxl)
library(ggplot2)

bmd1 <- read_excel(path="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\data2.xlsx", 
                   sheet=6)

bmd2 <- arrange(bmd1, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

#saveRDS(all, "Z:\\ENM Categories\\Framework Update 2019\\05_viz\\all.rds")
all <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\05_viz\\all.rds")

all$cluster.Complete <- as.factor(all$cluster.Complete)
all$cluster.Ward <- as.factor(all$cluster.Ward)

legend_title <- "Hierarchical Cluster"

ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=cluster.Complete)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Complete Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=cluster.Complete)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Complete Linkage", color=legend_title) +
  theme(legend.position=c(0.2,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=cluster.Ward)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=cluster.Ward)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.2,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())
  