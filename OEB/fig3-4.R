library(dplyr); library(ggplot2);

################# Data ################################

d <- read.csv(file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/fig3-4_R_data.csv",
              header=T)
d$index <- seq(1:nrow(d))

#No REL for Cerium; only want amorphous Silica
d2 <- filter(d, Formatted.Material != "Silica, crystalline") %>% 
      filter(Formatted.Material != "Cerium oxide") %>%
      select(-X)

d2$OEB <- as.numeric(d2$OEB)

d2 <- d2 %>% rename(Nanomaterial=Formatted.Material) %>% 
             rename(`REL (mg/m3)`=REL..mg.m3.) %>%
             rename(`Endpoint Type`=Endpoint.Type)

d3 <- d2 %>% filter(Scale=="Nano")

# focus on most stringent OEB by material and endpoint
d4 <- d3 %>% group_by(Nanomaterial, `Endpoint Type`) %>% summarize(OEB=min(OEB))
d4b <- left_join(d4, d3, by="OEB")
d4c <- d4b %>% select(-Nanomaterial.y, -`Endpoint Type.y`) %>% rename(Nanomaterial=Nanomaterial.x, `Endpoint Type`=`Endpoint Type.x`)

# focus on most stringent OEB by material
d5 <- d3 %>% group_by(Nanomaterial) %>% summarize(OEB=min(OEB))
d5b <- left_join(d5, d3, by="OEB")
d5c <- d5b %>% select(-Nanomaterial.y) %>% rename(Nanomaterial=Nanomaterial.x)


########################  Plots ########################################

# original, ugly plot with all endpoints and scales
g1 <- ggplot(data=d2, aes(x=log10(`REL (mg/m3)`), y=OEB, color=Nanomaterial)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Microscale and Nanoscale") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2.75))

g1

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v1all_points_v2.pdf",
       plot=g1,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")


# focus on nanomaterials, all endpoints
g2 <- ggplot(data=d3, aes(x=log10(`REL (mg/m3)`), y=OEB, color=Nanomaterial)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2))

g2

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v2nano_v2.pdf",
       plot=g2,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")


# highlight endpoints
g3 <- ggplot(data=d3, aes(x=log10(`REL (mg/m3)`), y=OEB, color=Nanomaterial, shape=`Endpoint Type`)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only with Endpoint Type") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2))

g3

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v3nano_with_endpt_v2.pdf",
       plot=g3,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")



# facet by nanomaterial
g4 <- ggplot(data=d3, aes(x=log10(`REL (mg/m3)`), y=OEB, shape=`Endpoint Type`)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only with Endpoint Type") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2.75)) + 
  facet_wrap(~ Nanomaterial, ncol=3)

g4

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v4nano_facet_v2.pdf",
       plot=g4,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")

# facet by nanomaterial and endpoint
g5 <- ggplot(data=d3, aes(x=log10(`REL (mg/m3)`), y=OEB)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only with Endpoint Type") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2.75)) + 
  facet_wrap(Nanomaterial ~ `Endpoint Type`)

g5

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v5nano_endpt_facet_v2.pdf",
       plot=g5,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")



# most stringent by material, endpoint
d4c$OEB[3] <- 2.8 #manual adjustment of a Carbon black point
d4c$OEB[10] <- 1.1 #manual adjustment of Silica
d4c$OEB[16] <- 2.75 #manual adjustment of Zinc
g6 <- ggplot(data=d4c, aes(x=log10(`REL (mg/m3)`), y=OEB, color=Nanomaterial, shape=`Endpoint Type`)) +
  geom_point(size=4.5,color="black") +
  geom_point(size=2.25, aes(color=Nanomaterial)) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A"),
                     limits=c(NA,5)) +
  scale_x_continuous(labels=c("0.001", "0.01", "0.1", "1", "10"),
                     limits=c(NA,1)) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and \nNIOSH recommended exposure limits (RELs) for high production \nnanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only, Most Stringent Band by Endpoint") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=1.75),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color='black'))

g6

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v6nano_endpoint_stringent_120324.pdf",
       plot=g6,
       device=pdf,
       dpi=300,
       width=7,
       height=6.5,
       units="in")



# most stringent by material
g7 <- ggplot(data=d5c, aes(x=log10(`REL (mg/m3)`), y=OEB, color=Nanomaterial, shape=`Endpoint Type`)) +
  geom_point(size=2) +
  scale_y_continuous(breaks=c(0,1,2,3,4,5),
                     labels=c("","band E", "band D", "band C", "band B", "band A")) +
  scale_x_continuous(labels=c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
  labs(title="Figure 3-4. Comparison of occupational exposure band (OEB) estimates and NIOSH recommended exposure limits (RELs) for high production nanomaterials [WHO 2017] with Indium and Graphene",
       subtitle="Nanoscale Only, Most Stringent Band by Nanomaterial") +
  xlab(bquote('Recommended Exposure Limit (REL) (mg/'*m^3*')')) +
  ylab("Occupational Exposure Band Estimates") + 
  theme_bw() +
  theme(axis.text.y=element_text(angle=90, hjust=2.75))

g7

ggsave(filename="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/v7nano_stringent_v2.pdf",
       plot=g7,
       device=pdf,
       dpi=300,
       width=7.5,
       height=10,
       units="in")
