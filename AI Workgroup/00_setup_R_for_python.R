install.packages("devtools")
install.packages("Rcpp")

repos <- c("https://ghrr.github.io/drat", "https://cloud.r-project.org")
install.packages("RcppTOML", repos=repos)


install.packages("reticulate")

library(reticulate)

repl_python()

py_install("pandas")
