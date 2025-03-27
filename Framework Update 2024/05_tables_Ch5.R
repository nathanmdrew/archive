library(dplyr)
library(ggplot2)
#library(Hmisc)     #describe

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/04_output/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/05_output/"

d1 <- readRDS(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/trimmed_data.RDS")


### Figure (really a table but visual) 5.2a-d
### Characteristics of the particulate substances evaluated in these analyses, 
### including particle size scale (Figure 5-2a), chemical composition, broad 
### category (Figure 5-2b), particle shape (Figure 5-2c), and material 
### composition (Figure 5-2d)
t5.2a <- d1 %>% group_by(Scale_rev) %>% summarize(tally=n())
t5.2a

t5.2b <- d1 %>% group_by(Material_Category) %>% summarize(tally=n())
t5.2b  

t5.2c <- d1 %>% group_by(Shape) %>% summarize(tally=n())
t5.2c

t5.2d <- d1 %>% group_by(material) %>% summarize(tally=n())
t5.2d

t5.2 <- bind_rows(t5.2a, t5.2b, t5.2c, t5.2d)
saveRDS(t5.2, file=paste0(pathout,"fig5.2.RDS"))
write.csv(t5.2, file=paste0(pathout, "fig5.2.csv"))


### Table 5.1 Categorical OEL estimates for acute inflammation in rats and mice 
### (4% PMNs above background, 0–3 days post-exposure); nanoscale and microscale 
### particle lung dose 
t5.1.k4 <- d1 %>% group_by(k4) %>% summarize(fifthPctile = quantile(BMDL, 0.05))
t5.1.k4$hec <- t5.1.k4$fifthPctile*(102/0.4)/1000
t5.1.k4$hecTWA <- t5.1.k4$hec/(9.6*0.2)
t5.1.k4$cOEL <- t5.1.k4$hecTWA/15
t5.1.k4$OEB <- case_when(
  t5.1.k4$cOEL < 0.001 ~ "F (<0.001)",
  t5.1.k4$cOEL < 0.01 ~ "E (<0.01)",
  t5.1.k4$cOEL < 0.1 ~ "D (>0.01 to 0.1)",
  t5.1.k4$cOEL < 1 ~ "C (>0.1 to 1)",
  t5.1.k4$cOEL < 10 ~ "B (>1 to 10)",
  t5.1.k4$cOEL > 10 ~ "A (>10)"
)

t5.1.k5 <- d1 %>% group_by(k5) %>% summarize(fifthPctile = quantile(BMDL, 0.05))
t5.1.k5$hec <- t5.1.k5$fifthPctile*(102/0.4)/1000
t5.1.k5$hecTWA <- t5.1.k5$hec/(9.6*0.2)
t5.1.k5$cOEL <- t5.1.k5$hecTWA/15
t5.1.k5$OEB <- case_when(
  t5.1.k5$cOEL < 0.001 ~ "F (<0.001)",
  t5.1.k5$cOEL < 0.01 ~ "E (<0.01)",
  t5.1.k5$cOEL < 0.1 ~ "D (>0.01 to 0.1)",
  t5.1.k5$cOEL < 1 ~ "C (>0.1 to 1)",
  t5.1.k5$cOEL < 10 ~ "B (>1 to 10)",
  t5.1.k5$cOEL > 10 ~ "A (>10)"
)

t5.1 <- bind_rows(t5.1.k4, t5.1.k5)

#keep running, but change GROUP_BY to the remaining cluster vars
# couldn't get a function to work right
# k6, k7, k8, k9, k10, kOOM
t5.1.k5 <- d1 %>% group_by(kOOM) %>% summarize(fifthPctile = quantile(BMDL, 0.05))
t5.1.k5$hec <- t5.1.k5$fifthPctile*(102/0.4)/1000
t5.1.k5$hecTWA <- t5.1.k5$hec/(9.6*0.2)
t5.1.k5$cOEL <- t5.1.k5$hecTWA/15
t5.1.k5$OEB <- case_when(
  t5.1.k5$cOEL < 0.001 ~ "F (<0.001)",
  t5.1.k5$cOEL < 0.01 ~ "E (<0.01)",
  t5.1.k5$cOEL < 0.1 ~ "D (>0.01 to 0.1)",
  t5.1.k5$cOEL < 1 ~ "C (>0.1 to 1)",
  t5.1.k5$cOEL < 10 ~ "B (>1 to 10)",
  t5.1.k5$cOEL > 10 ~ "A (>10)"
)

t5.1 <- bind_rows(t5.1, t5.1.k5)


saveRDS(t5.1, file=paste0(pathout,"t5.1.RDS"))
write.csv(t5.1, file=paste0(pathout, "t5.1.csv"))


### Table 5.2 - Material counts within hazard potency group 
table5.2.k4 <- table(d1$material, d1$k4)
saveRDS(table5.2.k4, file=paste0(pathout,"table5.2.k4.RDS"))
write.csv(table5.2.k4, file=paste0(pathout, "table5.2.k4.csv"))

table5.2 <- table(d1$material, d1$k5)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k5.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k5.csv"))

table5.2 <- table(d1$material, d1$k6)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k6.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k6.csv"))

table5.2 <- table(d1$material, d1$k7)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k7.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k7.csv"))

table5.2 <- table(d1$material, d1$k8)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k8.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k8.csv"))

table5.2 <- table(d1$material, d1$k9)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k9.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k9.csv"))

table5.2 <- table(d1$material, d1$k10)
saveRDS(table5.2, file=paste0(pathout,"table5.2.k10.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.k10.csv"))

table5.2 <- table(d1$material, d1$kOOM)
saveRDS(table5.2, file=paste0(pathout,"table5.2.kOOM.RDS"))
write.csv(table5.2, file=paste0(pathout, "table5.2.kOOM.csv"))


### Table 5.3 Physicochemical properties within hazard potency groups

s <- d1 %>% select(Diameter, Surface_Area, k4, k5, k6, k7, k8, k9, k10, kOOM)

s$Diameter[s$Diameter==-99] <- NA
s$Surface_Area[s$Surface_Area==-99] <- NA

#repeat code below, update GROUP_BY and output names for each cluster var
s2 <- s %>% group_by(kOOM) %>% summarize(tally=n(),
                                       medDiam = median(Diameter, na.rm=T),
                                       minDiam = min(Diameter, na.rm=T),
                                       maxDiam = max(Diameter, na.rm=T),
                                       notMissDiam = sum(!is.na(Diameter)),
                                       medSSA = median(Surface_Area, na.rm=T),
                                       minSSA = min(Surface_Area, na.rm=T),
                                       maxSSA = max(Surface_Area, na.rm=T),
                                       notMissSSA = sum(!is.na(Surface_Area))
                                       )

t5.3 <- t(s2)

saveRDS(t5.3, file=paste0(pathout,"table5.3.kOOM.RDS"))
write.csv(t5.3, file=paste0(pathout, "table5.3.kOOM.csv"))



######  Added below 11/25/2024 ######################
### Figure ??? - Regression for SSA and Diameter
# linreg.diam <- lm(as.numeric(k8) ~ Diameter, data=s)
# summary(linreg.diam)
# anova(linreg.diam)
# plot(linreg.diam)
# cor(s$Diameter, as.numeric(s$k8))
# plot(s$Diameter, as.numeric(s$k8))
# ggplot(data=s, aes(x=Diameter, y=as.numeric(k8))) +
#   geom_point() +
#   geom_smooth(method="lm")
# 
# 
# linreg.ssa <- lm(as.numeric(k8) ~ Surface_Area, data=s)
# summary(linreg.ssa)
# anova(linreg.ssa)
# plot(linreg.ssa)
# cor(s$Surface_Area, as.numeric(s$k8))
# plot(s$Surface_Area, as.numeric(s$k8))
# plot(as.numeric(s$k8), s$Surface_Area)
# ggplot(data=s, aes(x=Surface_Area, y=as.numeric(k8))) +
#   geom_point() +
#   geom_smooth(method="lm")



s2 <- d1 %>% select(Diameter, Surface_Area, BMD, k4, k5, k6, k7, k8, k9, k10, kOOM)

s2$Diameter[s2$Diameter==-99] <- NA
s2$Surface_Area[s2$Surface_Area==-99] <- NA



linreg.diam2 <- lm(BMD ~ Diameter, data=s2)
t <- summary(linreg.diam2)
pvalue <- round(t$coefficients[2,4], 3)

g <- ggplot(data=s2, aes(x=Diameter, y=BMD)) +
  geom_point() +
  geom_smooth(method="lm") + 
  theme_bw() +
  xlab("Diameter (nm)") + 
  ylab(expression("Benchmark Dose ("*mu*"g/g lung)")) +
  annotate("text", x=2500, y=500, label=paste0("p-value = ", pvalue))

g

ggsave(filename=paste0(pathout,"BMD_Diameter_Regression_Plot.pdf"), plot=g, device="pdf",
       dpi=300)


linreg.ssa2 <- lm(BMD ~ Surface_Area, data=s2)
summary(linreg.ssa2)
t <- summary(linreg.ssa2)
pvalue <- round(t$coefficients[2,4], 3)
cor(s2$Diameter, s2$BMD)

g <- ggplot(data=s2, aes(x=Surface_Area, y=BMD)) +
  geom_point() +
  geom_smooth(method="lm") +
  theme_bw() +
  xlab("Surface Area (m\U00B2/g)") + 
  ylab(expression("Benchmark Dose ("*mu*"g/g lung)")) +
  annotate("text", x=400, y=250, label=paste0("p-value = ", pvalue))

g

ggsave(filename=paste0(pathout,"BMD_SurfArea_Regression_Plot.pdf"), plot=g, device="pdf",
       dpi=300)
