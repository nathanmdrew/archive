library(readxl)
library(dplyr)
library(ggplot2)

pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/01_output/"

d <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/data4.xlsx",
                sheet="Data 2024",
                col_names=T)
d$rownum <- seq(1:nrow(d))

d2 <- filter(d, indi_exclude==0)
summary(d2$BMD)

d2 <- arrange(d2, BMD)

dis <- dist(d2$BMD, method="euclidean")

h <- hclust(dis, method="ward.D2")
d2$k4 <- cutree(h, k=4)
d2$k5 <- cutree(h, k=5)
d2$k6 <- cutree(h, k=6)
d2$k7 <- cutree(h, k=7)
d2$k8 <- cutree(h, k=8)
d2$k9 <- cutree(h, k=9)
d2$k10 <- cutree(h, k=10)

s4 <- d2 %>% group_by(k4) %>% summarize(tally=n(),
                                       minBMD=min(BMD),
                                       maxBMD=max(BMD),
                                       minBMDL=min(BMDL),
                                       maxBMDL=max(BMDL))
s4

s5 <- d2 %>% group_by(k5) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s5

s6 <- d2 %>% group_by(k6) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s6

s7 <- d2 %>% group_by(k7) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s7

s8 <- d2 %>% group_by(k8) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s8

s9 <- d2 %>% group_by(k9) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s9

s10 <- d2 %>% group_by(k10) %>% summarize(tally=n(),
                                        minBMD=min(BMD),
                                        maxBMD=max(BMD),
                                        minBMDL=min(BMDL),
                                        maxBMDL=max(BMDL))
s10


unique(d2$Route)

inh <- c("inhalation", "Inhalation", "nose only inhalation", "whole body inhalation", "Inh")
d2$ind_inhalation <- if_else(d2$Route %in% inh, 1, 0)
summary(as.factor(d2$ind_inhalation))

####  Previously clustered without Inhalations
# 
# d3 <- filter(d2, ind_inhalation==0)
# 
# dis <- dist(d3$BMD, method="euclidean")
# 
# h <- hclust(dis, method="ward.D2")
# d3$k4 <- cutree(h, k=4)
# d3$k5 <- cutree(h, k=5)
# d3$k6 <- cutree(h, k=6)
# d3$k7 <- cutree(h, k=7)
# d3$k8 <- cutree(h, k=8)
# d3$k9 <- cutree(h, k=9)
# d3$k10 <- cutree(h, k=10)
# 
# s <- d3 %>% group_by(k4) %>% summarize(tally=n(),
#                                        minBMD=min(BMD),
#                                        maxBMD=max(BMD),
#                                        minBMDL=min(BMDL),
#                                        maxBMDL=max(BMDL))
# s





bmd2 <- arrange(d2, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

all$k4 <- as.factor(all$k4)
all$k5 <- as.factor(all$k5)
all$k6 <- as.factor(all$k6)
all$k7 <- as.factor(all$k7)
all$k8 <- as.factor(all$k8)
all$k9 <- as.factor(all$k9)
all$k10 <- as.factor(all$k10)

legend_title <- "Hierarchical Cluster"

g4 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k4)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g5 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k5)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g6 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k6)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g7 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k7)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g8 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k8)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g9 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k9)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

g10 <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k10)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())




all$kInh <- if_else(all$Route %in% inh, as.factor("Inhalation"), as.factor("Non-inhalation"))

legend_title <- "Route of Exposure"
gInh <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=kInh)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%)",
       color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())



d3 <- select(d2, rownum, k4, k5, k6, k7, k8, k9, k10)

d4 <- left_join(d, d3, by="rownum")

saveRDS(d4, file=paste0(pathout,"data4_and_clusters.RDS"))
write.csv(d4, file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/data4_and_clusters.csv")

ggsave(plot=g4, filename=paste0(pathout,"g4.pdf"), dpi=300)
ggsave(plot=g5, filename=paste0(pathout,"g5.pdf"), dpi=300)
ggsave(plot=g6, filename=paste0(pathout,"g6.pdf"), dpi=300)
ggsave(plot=g7, filename=paste0(pathout,"g7.pdf"), dpi=300)
ggsave(plot=g8, filename=paste0(pathout,"g8.pdf"), dpi=300)
ggsave(plot=g9, filename=paste0(pathout,"g9.pdf"), dpi=300)
ggsave(plot=g10, filename=paste0(pathout,"g10.pdf"), dpi=300)
ggsave(plot=gInh, filename=paste0(pathout,"gInh.pdf"), dpi=300)




##### Update with logarithmic plots - 11/27/2024
### NOTE: this was already created in program 06
d4 <- readRDS(file=paste0(pathout,"data4_and_clusters.RDS"))
d5 <- filter(d4, indi_exclude==0)

bmd2 <- arrange(d5, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

all$k4 <- as.factor(all$k4)
all$k5 <- as.factor(all$k5)
all$k6 <- as.factor(all$k6)
all$k7 <- as.factor(all$k7)
all$k8 <- as.factor(all$k8)
all$k9 <- as.factor(all$k9)
all$k10 <- as.factor(all$k10)

legend_title <- "Hierarchical Cluster"

g8 <- ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=k8)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position.inside=c(0.2,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())
g8

ggsave(plot=g8, filename=paste0(pathout,"g8_log10.pdf"), dpi=300)



# highlight Inhalation studies as Cluster 0
# all$k4 <- if_else(all$Route %in% inh, as.factor(0), all$k4)
# 
# ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k4)) +
#   geom_point() +
#   geom_line() +
#   labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
#        subtitle="Ward's Method Linkage", color=legend_title) +
#   theme(legend.position=c(0.8,0.5),
#         axis.text.y=element_blank(),
#         axis.ticks.y=element_blank())




### Previously plotted clusters WITHOUT inhalation
# 
# 
# bmd2 <- arrange(d3, BMD)
# 
# bmd2$index2 <- seq(1:nrow(bmd2))
# 
# bmdl1 <- select(bmd2, -BMD)
# bmdl1 <- bmdl1 %>% rename(BMD=BMDL)
# 
# all <- bind_rows(bmd2,bmdl1)
# all <- arrange(all, index2)
# 
# all$k4 <- as.factor(all$k4)
# 
# legend_title <- "Hierarchical Cluster"
# 
# ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=k4)) +
#   geom_point() +
#   geom_line() +
#   labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
#        subtitle="Ward's Method Linkage", color=legend_title) +
#   theme(legend.position=c(0.8,0.5),
#         axis.text.y=element_blank(),
#         axis.ticks.y=element_blank())





