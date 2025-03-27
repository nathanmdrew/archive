# check Ward vs. Ward2
# dist or dist^2

qc.bmd <- select(pod.all2, index, potency_rank, BMD.x)
qc.bmd <- arrange(qc.bmd, BMD.x)

qc.dist <- dist(qc.bmd$BMD.x)

qc.ward.lin <- hclust(qc.dist, method="ward.D")
qc.ward.sq <- hclust(qc.dist^2, method="ward.D")

qc.ward2.lin <- hclust(qc.dist, method="ward.D2")
qc.ward2.sq <- hclust(qc.dist^2, method="ward.D2")


qc.clust.wl <- cutree(qc.ward.lin, k=4)
qc.clust.ws <- cutree(qc.ward.sq, k=4)
qc.clust.w2l <- cutree(qc.ward2.lin, k=4)
qc.clust.w2s <- cutree(qc.ward2.sq, k=4)

qc.bmd$ward.lin <- qc.clust.wl
qc.bmd$ward.sq <- qc.clust.ws
qc.bmd$ward2.lin <- qc.clust.w2l
qc.bmd$ward2.sq <- qc.clust.w2s

# Ward (linear dist) = Ward (sq. dist) = Ward2 (linear dist)
# Ward2 (squared dist) is different

