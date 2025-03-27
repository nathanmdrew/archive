###############################3
###  Plot Figures 4-1, 4-2

library(ggplot2)
library(dplyr)
library(readxl)
library(directlabels)

d0 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_EID_NanoRA\\CatOEL  Doc Draft\\Tables\\DISCUSSION_OEB_Band_Summary_v2.xlsx", 
                 sheet=8) #"for plots in R"

d1 <- d0

d1$Material2 <- d1$Material

d1$Material2[d1$Material %in% c("Abrasive Blasting Agent: Blasting Sand","Abrasive Blasting Agent: Specular Hematite")] <- "Abrasive blasting agents"
d1$Material2[d1$Material == "Ag"] <- "Silver"
d1$Material2[d1$Material == "Au"] <- "Gold"
d1$Material2[d1$Material %in% c("CB","CB (HSCb)","CB (Printex90)")] <- "Carbon black"
d1$Material2[d1$Material == "CeO2"] <- "Cerium oxide"
d1$Material2[d1$Material %in% c("Fe3O4", "Fe3O4 (Magnetite)")] <- "Magnetite"
d1$Material2[d1$Material == "FeCO3 (Siderite)"] <- "Siderite"
d1$Material2[d1$Material == "SiO2"] <- "Silica"
d1$Material2[d1$Material == "TiO2"] <- "Titanium dioxide (nanoscale)"
d1$Material2[d1$Material == "TiO2 (Micro)"] <- "Titanium dioxide (microscale)"
d1$Material2[d1$Material == "ZnO"] <- "Zinc oxide"

d1$plot.y[d1$Material2=="Carbon black"] <- 8
d1$plot.y[d1$Material2=="Magnetite"] <- 15

#d1$plot.y <- if_else(d1$plot.y>2, d1$plot.y-1, d1$plot.y, -99) #dumb fix for grouping sands

#d1 <- arrange(d1, plot.y, desc(plot.x))

d1$moa <- as.factor(d1$moa)
#d1$plot.y2 <- d1$plot.y * 2

#temp <- data.frame(plot.y2=seq(from=1, to=69, by=2), plot.x=5, moa=NA, Material2=NA)
#temp$plot.x <- if_else(temp$plot.y2 != 1, 0, 5, 0)

#

#d2 <- arrange(d2, plot.y2)

temp <- data.frame(plot.y=36, plot.x=5, moa=NA, Material2=NA)
d2 <- bind_rows(temp, d1)

d3 <- d2[2:nrow(d2),]

legend_title <- "Mode of Action"

# Fig 4-1
ggplot(data=d2, aes(x=plot.x, y=plot.y, group=plot.y, color=moa)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))



top9 <- filter(d2, Material2 %in% c("Zinc oxide", "Titanium dioxide (nanoscale)",
                                    "SWCNT", "MWCNT", "Silica", "Cerium oxide",
                                    "Carbon black", "Silver"))

top9$plot.y[top9$Material2=="Silver"] <- 1
top9$plot.y[top9$Material2=="Carbon black"] <- 2
top9$plot.y[top9$Material2=="Cerium oxide"] <- 3
top9$plot.y[top9$Material2=="MWCNT"] <- 4
top9$plot.y[top9$Material2=="SWCNT"] <- 5
top9$plot.y[top9$Material2=="Silica"] <- 6
top9$plot.y[top9$Material2=="Titanium dioxide (nanoscale)"] <- 7
top9$plot.y[top9$Material2=="Zinc oxide"] <- 8

#Fig 4-2
ggplot(data=top9, aes(x=plot.x, y=plot.y, group=plot.y, color=moa)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="Highest commercial volume", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


# Revisions - 9/2/2020
# Goals: Combine "Solubles"
# Sort by MoA

# remove the NA category
d3 <- d2[2:nrow(d2),]

# Revised Fig4-1 - no NA MoA
ggplot(data=d3, aes(x=plot.x, y=plot.y, group=plot.y, color=moa)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))

str(d3$moa)
d3$moa2 <- as.character(d3$moa)

d3$moa2[d3$moa2=="Soluble, high toxicity"] <- "Soluble"
d3$moa2[d3$moa2=="Soluble, low toxicity"] <- "Soluble"

d3$moa2 <- as.factor(d3$moa2)

# Revised Fig4-1 - no NA MoA, combined Soluble
ggplot(data=d3, aes(x=plot.x, y=plot.y, group=plot.y, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


d3 <- arrange(d3, moa2, Material2)

keys <- d3 %>% distinct(moa2, Material2)
keys$plot.y2 <- seq(1:nrow(keys))

d4 <- left_join(d3, keys)

# Revised Fig4-1 - no NA MoA, combined Soluble, sorted by MoA
ggplot(data=d4, aes(x=plot.x, y=plot.y2, group=plot.y2, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))



##########
###  Revisions 9/10/2020
###     Eileen changed MoA groups, wants other sortings

d5 <- d4

d5$moa2 <- as.character(d5$moa2)

d5$moa2[d5$Material2=="Silica"] <- "Poorly soluble, low toxicity"
d5$Material2[d5$Material=="SiO2"] <- "Silicon dioxide, amorphous"
d5$moa2[d5$Material2=="Molybdenum trioxide"] <- "Poorly soluble, low toxicity"
d5$moa2[d5$Material2=="ortho-Phthalaldehyde"] <- "Unknown solubility"
d5$moa2[d5$Material2=="Chromium"] <- "Soluble"
d5$Material2[d5$Material=="Chromium"] <- "Chromium, hexavalent"
d5$moa2[d5$moa2=="Low Solubility, high toxicity"] <- "Low solubility, high toxicity"

d5$moa2 <- as.factor(d5$moa2)


d5 <- arrange(d5, desc(moa2), desc(Material2))

rm(keys)
keys <- d5 %>% distinct(moa2, Material2)
keys$plot.y3 <- seq(1:nrow(keys))

d6 <- left_join(d5, keys)

# Revised Fig4-1 - no NA MoA, combined Soluble, sorted by MoA
ggplot(data=d6, aes(x=plot.x, y=plot.y3, group=plot.y3, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


# omit pesticides for User's Guide
d7 <- d6 %>% filter(x != 70, x != 71, x != 72)

# Revised Fig4-1 - no NA MoA, combined Soluble, sorted by MoA
ggplot(data=d7, aes(x=plot.x, y=plot.y3, group=plot.y3, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))



top9 <- filter(d7, Material2 %in% c("Zinc oxide", "Titanium dioxide (nanoscale)",
                                    "SWCNT", "MWCNT", "Silicon dioxide, amorphous", "Cerium oxide",
                                    "Carbon black", "Silver"))

top9$plot.y[top9$Material2=="Silver"] <- 2
top9$plot.y[top9$Material2=="Carbon black"] <- 6
top9$plot.y[top9$Material2=="Cerium oxide"] <- 5
top9$plot.y[top9$Material2=="MWCNT"] <- 8
top9$plot.y[top9$Material2=="SWCNT"] <- 7
top9$plot.y[top9$Material2=="Silicon dioxide, amorphous"] <- 4
top9$plot.y[top9$Material2=="Titanium dioxide (nanoscale)"] <- 3
top9$plot.y[top9$Material2=="Zinc oxide"] <- 1

#Fig 4-2 revised
ggplot(data=top9, aes(x=plot.x, y=plot.y, group=plot.y, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="Highest commercial volume", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))




########
### Revisions 9/23/2020
###
###     Split up Fig 4-1 revised by endpoint
###         Summarize PoD types

#use d6 and d7

d6.neo <- d6 %>% filter(endpt=="Lung Neoplasia")
d6.fib <- d6 %>% filter(endpt=="Lung Fibrosis")
d6.inf <- d6 %>% filter(endpt=="Lung Inflammation")

d6.neo$plot.y4 <- seq(1:nrow(d6.neo))

fib.keys <- d6.fib %>% distinct(Material2)
fib.keys$plot.y4 <- seq(1:nrow(fib.keys))
d6.fib <- left_join(d6.fib, fib.keys)


inf.keys <- d6.inf %>% distinct(Material2)
inf.keys$plot.y4 <- seq(1:nrow(inf.keys))
d6.inf <- left_join(d6.inf, inf.keys)

# Revised Fig4-1 - no NA MoA, combined Soluble, sorted by MoA
# Only Neoplasia
ggplot(data=d6.neo, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Neoplasia", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))

# Only Fibrosis
ggplot(data=d6.fib, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Fibrosis", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


# Only Inflammation
ggplot(data=d6.inf, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Inflammation", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


d7.neo <- d7 %>% filter(endpt=="Lung Neoplasia")
d7.fib <- d7 %>% filter(endpt=="Lung Fibrosis")
d7.inf <- d7 %>% filter(endpt=="Lung Inflammation")


d7.neo$plot.y4 <- seq(1:nrow(d7.neo))

fib.keys <- d7.fib %>% distinct(Material2)
fib.keys$plot.y4 <- seq(1:nrow(fib.keys))
d7.fib <- left_join(d7.fib, fib.keys)


inf.keys <- d7.inf %>% distinct(Material2)
inf.keys$plot.y4 <- seq(1:nrow(inf.keys))
d7.inf <- left_join(d7.inf, inf.keys)



# Only Neoplasia
ggplot(data=d7.neo, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Neoplasia", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))

# Only Fibrosis
ggplot(data=d7.fib, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Fibrosis", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


# Only Inflammation
ggplot(data=d7.inf, aes(x=plot.x, y=plot.y4, group=plot.y4, color=moa2)) +
  geom_point(position=position_jitter(w=0.05,h=0)) +
  #geom_jitter(width=0.05) +
  geom_line() +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=.75, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="All materials - Lung Inflammation", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))


summ <- d6 %>% group_by(endpt, pod_type) %>% summarize(frequency=n())
#write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\06_TR_band_viz_OUTPUT\\summary_endpt_podtype.csv")

summary(as.factor(d6$Band))

summ2 <- d6 %>% group_by(endpt, Band) %>% summarize(Freq=n())







###################################################
###  Revision for All Hands Presentation Feb 3 2021
###     Increase sizes, add vertical/more jitter, remove Y grid

str(top9$plot.x)
#Fig 4-2 revised
ggplot(data=top9, aes(x=plot.x, y=plot.y, group=plot.y, color=moa2)) +
  geom_point(size=3.5, alpha=0.6, position=position_jitter(w=0.15,h=0.15)) +
  #geom_jitter(width=0.05) +
  #geom_line(size=2) +
  #geom_label_repel(aes(label=Material2), nudge_x=1, na.rm=T) +
  geom_dl(aes(label=Material2), method=list(dl.trans(x=x+.4), cex=1.25, "last.points")) +
  labs(x=bquote("Exposure Band"~(mg/m^3)), y=NULL, title="Band ranges by material class",
       subtitle="Highest commercial volume", color=legend_title) +
  theme_bw() +
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.grid.minor.y=element_blank()) +
  scale_x_continuous(limits=c(0,6))
  #scale_x_discrete(breaks=c("1","2","3","4","5"),
  #                          labels=c("1"="E (<0.01)", 
  #                          "2"="D (>0.01-0.1)", 
  #                          "3"="C (>0.1-1)", 
  #                          "4"="B (>1-10)", 
  #                          "5"="A (>10)"))
