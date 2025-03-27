rf.loo <- function (mtryval) {

  save.loo.rf <- vector(mode="list", length=nrow(d1))
  save.loo.pred <- vector(mode="list", length=nrow(d1))

  for (jj in 1:(nrow(d1.resort)-1)) {
  
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
                             mtry=mtryval)
  save.loo.rf[[jj]] <- current.rf
  
  current.pred <- predict(current.rf, newdata=current.test)
  save.loo.pred[[jj]] <- current.pred
  
  } # jj loop end

  save.loo.pred[[124]] <- 1

  #update file name for MTRY
  saveRDS(save.loo.rf, file=paste0(pathout, paste0("save.loo.rf.mtry",mtryval,".RDS")))
  saveRDS(save.loo.pred, file=paste0(pathout, paste0("save.loo.pred.mtry",mtryval,".RDS")))

} #function end

start_time <- Sys.time()
for (cc in 1:22) {
  rf.loo(mtry=cc)
}
end_time <- Sys.time()
end_time - start_time #31 minutes

