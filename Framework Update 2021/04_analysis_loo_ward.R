save.rf1 <- vector(mode="list", length=nrow(d1))
save.rf2 <- vector(mode="list", length=nrow(d1))
save.rf3 <- vector(mode="list", length=nrow(d1))
save.rf4 <- vector(mode="list", length=nrow(d1))
save.rf5 <- vector(mode="list", length=nrow(d1))
save.rf6 <- vector(mode="list", length=nrow(d1))
save.rf7 <- vector(mode="list", length=nrow(d1))
save.rf8 <- vector(mode="list", length=nrow(d1))
save.rf9 <- vector(mode="list", length=nrow(d1))
save.rf10 <- vector(mode="list", length=nrow(d1))
save.rf11 <- vector(mode="list", length=nrow(d1))
save.rf12 <- vector(mode="list", length=nrow(d1))
save.rf13 <- vector(mode="list", length=nrow(d1))
save.rf14 <- vector(mode="list", length=nrow(d1))
save.rf15 <- vector(mode="list", length=nrow(d1))
save.rf16 <- vector(mode="list", length=nrow(d1))
save.rf17 <- vector(mode="list", length=nrow(d1))
save.rf18 <- vector(mode="list", length=nrow(d1))
save.rf19 <- vector(mode="list", length=nrow(d1))
save.rf20 <- vector(mode="list", length=nrow(d1))
save.rf21 <- vector(mode="list", length=nrow(d1))
save.rf22 <- vector(mode="list", length=nrow(d1))

save.pred1 <- vector(mode="list", length=nrow(d1))
save.pred2 <- vector(mode="list", length=nrow(d1))
save.pred3 <- vector(mode="list", length=nrow(d1))
save.pred4 <- vector(mode="list", length=nrow(d1))
save.pred5 <- vector(mode="list", length=nrow(d1))
save.pred6 <- vector(mode="list", length=nrow(d1))
save.pred7 <- vector(mode="list", length=nrow(d1))
save.pred8 <- vector(mode="list", length=nrow(d1))
save.pred9 <- vector(mode="list", length=nrow(d1))
save.pred10 <- vector(mode="list", length=nrow(d1))
save.pred11 <- vector(mode="list", length=nrow(d1))
save.pred12 <- vector(mode="list", length=nrow(d1))
save.pred13 <- vector(mode="list", length=nrow(d1))
save.pred14 <- vector(mode="list", length=nrow(d1))
save.pred15 <- vector(mode="list", length=nrow(d1))
save.pred16 <- vector(mode="list", length=nrow(d1))
save.pred17 <- vector(mode="list", length=nrow(d1))
save.pred18 <- vector(mode="list", length=nrow(d1))
save.pred19 <- vector(mode="list", length=nrow(d1))
save.pred20 <- vector(mode="list", length=nrow(d1))
save.pred21 <- vector(mode="list", length=nrow(d1))
save.pred22 <- vector(mode="list", length=nrow(d1))

# manually run
# save.rf and save.pred suffix num = mtry {1, 22}
for (jj in 1:(nrow(d1.resort)-1)){
  
  current.train <- filter(d1.resort, ii != jj)
  current.test  <- filter(d1.resort, ii == jj)
  
  current.rf <- randomForest(cluster.Ward.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                               Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                               Contaminants_ + Contaminant_Type + Contaminant_Amount +
                               Functionalized_Type + Purification_Type + Modification +
                               Solubility + Zeta_Potential + Surface_Charge + Density + 
                               Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                               Agglomerated_ + Material_Category + material,
                             data=current.train,
                             importance=T,
                             proximity=T,
                             mtry=22)
  save.rf22[[jj]] <- current.rf
  
  current.pred <- predict(current.rf, newdata=current.test)
  save.pred22[[jj]] <- current.pred
  
} 

#adjust for the omission of Cluster 3
#assume incorrect classification into Cluster 1
save.pred1[[124]] <- 1
save.pred2[[124]] <- 1
save.pred3[[124]] <- 1
save.pred4[[124]] <- 1
save.pred5[[124]] <- 1
save.pred6[[124]] <- 1
save.pred7[[124]] <- 1
save.pred8[[124]] <- 1
save.pred9[[124]] <- 1
save.pred10[[124]] <- 1
save.pred11[[124]] <- 1
save.pred12[[124]] <- 1
save.pred13[[124]] <- 1
save.pred14[[124]] <- 1
save.pred15[[124]] <- 1
save.pred16[[124]] <- 1
save.pred17[[124]] <- 1
save.pred18[[124]] <- 1
save.pred19[[124]] <- 1
save.pred20[[124]] <- 1
save.pred21[[124]] <- 1
save.pred22[[124]] <- 1

pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2021/04_analysis_OUTPUTS/"

saveRDS(save.rf1, file=paste0(pathout, "save.rf1.RDS"))
saveRDS(save.rf2, file=paste0(pathout, "save.rf2.RDS"))
saveRDS(save.rf3, file=paste0(pathout, "save.rf3.RDS"))
saveRDS(save.rf4, file=paste0(pathout, "save.rf4.RDS"))
saveRDS(save.rf5, file=paste0(pathout, "save.rf5.RDS"))
saveRDS(save.rf6, file=paste0(pathout, "save.rf6.RDS"))
saveRDS(save.rf7, file=paste0(pathout, "save.rf7.RDS"))
saveRDS(save.rf8, file=paste0(pathout, "save.rf8.RDS"))
saveRDS(save.rf9, file=paste0(pathout, "save.rf9.RDS"))
saveRDS(save.rf10, file=paste0(pathout, "save.rf10.RDS"))
saveRDS(save.rf11, file=paste0(pathout, "save.rf11.RDS"))
saveRDS(save.rf12, file=paste0(pathout, "save.rf12.RDS"))
saveRDS(save.rf13, file=paste0(pathout, "save.rf13.RDS"))
saveRDS(save.rf14, file=paste0(pathout, "save.rf14.RDS"))
saveRDS(save.rf15, file=paste0(pathout, "save.rf15.RDS"))
saveRDS(save.rf16, file=paste0(pathout, "save.rf16.RDS"))
saveRDS(save.rf17, file=paste0(pathout, "save.rf17.RDS"))
saveRDS(save.rf18, file=paste0(pathout, "save.rf18.RDS"))
saveRDS(save.rf19, file=paste0(pathout, "save.rf19.RDS"))
saveRDS(save.rf20, file=paste0(pathout, "save.rf20.RDS"))
saveRDS(save.rf21, file=paste0(pathout, "save.rf21.RDS"))
saveRDS(save.rf22, file=paste0(pathout, "save.rf22.RDS"))

saveRDS(save.pred1, file=paste0(pathout, "save.pred1.RDS"))
saveRDS(save.pred2, file=paste0(pathout, "save.pred2.RDS"))
saveRDS(save.pred3, file=paste0(pathout, "save.pred3.RDS"))
saveRDS(save.pred4, file=paste0(pathout, "save.pred4.RDS"))
saveRDS(save.pred5, file=paste0(pathout, "save.pred5.RDS"))
saveRDS(save.pred6, file=paste0(pathout, "save.pred6.RDS"))
saveRDS(save.pred7, file=paste0(pathout, "save.pred7.RDS"))
saveRDS(save.pred8, file=paste0(pathout, "save.pred8.RDS"))
saveRDS(save.pred9, file=paste0(pathout, "save.pred9.RDS"))
saveRDS(save.pred10, file=paste0(pathout, "save.pred10.RDS"))
saveRDS(save.pred11, file=paste0(pathout, "save.pred11.RDS"))
saveRDS(save.pred12, file=paste0(pathout, "save.pred12.RDS"))
saveRDS(save.pred13, file=paste0(pathout, "save.pred13.RDS"))
saveRDS(save.pred14, file=paste0(pathout, "save.pred14.RDS"))
saveRDS(save.pred15, file=paste0(pathout, "save.pred15.RDS"))
saveRDS(save.pred16, file=paste0(pathout, "save.pred16.RDS"))
saveRDS(save.pred17, file=paste0(pathout, "save.pred17.RDS"))
saveRDS(save.pred18, file=paste0(pathout, "save.pred18.RDS"))
saveRDS(save.pred19, file=paste0(pathout, "save.pred19.RDS"))
saveRDS(save.pred20, file=paste0(pathout, "save.pred20.RDS"))
saveRDS(save.pred21, file=paste0(pathout, "save.pred21.RDS"))
saveRDS(save.pred22, file=paste0(pathout, "save.pred22.RDS"))

