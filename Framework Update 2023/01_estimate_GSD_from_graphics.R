library(ggplot2)
library(dplyr)


fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a_autodetectAll.csv",
                  header=F)

fig2a$V2[fig2a$V2 < 0] <- 0
fig2a <- arrange(fig2a, V1)
names(fig2a) <- c("x", "y")
plot(fig2a$x, fig2a$y, main="Particle Size Distribution for 37nm amorphous silica", sub="Digitized, Lognormal",
     xlab="Size (nm)", ylab="Concentration (particles/mL)")
plot(log(fig2a$x), fig2a$y, main="Particle Size Distribution for 37nm amorphous silica", sub="Digitized, Normal",
     xlab="LN[Size (nm)]", ylab="Concentration (particles/mL)")

fig2a$cumy <- cumsum(fig2a$y)
fig2a$cumy_rescale <- fig2a$cumy / max(fig2a$cumy)

plot(log(fig2a$x), fig2a$cumy_rescale, main="Cumulative Distribution of Particle Sizes for 37nm amorphous silica", sub="Digitized, Normal",
     xlab="LN[Size (nm)]", ylab="Scaled Cumulative Concentration (particles/mL)")

#assuming the Fig2a data follow a normal distribution (log), fit a normal CDF
#minimize squared errors to estimate mean, sd
estNorm <- function(parms, x, y) {
  sum((y - pnorm(x, mean = parms[1], sd = parms[2]))^2)
}

fit <- optim(c(3, 2), 
             fn = estNorm, 
             x = log(fig2a$x), 
             y = fig2a$cumy_rescale)

fit
exp(fit$par[1]) #39
exp(fit$par[2]) #1.7

fig2a$fitted <- pnorm(log(fig2a$x), fit$par[1], fit$par[2])
plot(log(fig2a$x), fig2a$fitted)


theme_set(theme_bw())
ggplot(data = fig2a, aes(x = log(x), y = fig2a$cumy_rescale)) + geom_point(size = 3) +
  geom_line(data = fig2a, aes(x=log(x), y=fitted), size = 1, colour = "steelblue") +
  labs(main="Observed vs. Predicted Cumulative Distributions", 
        subtitle=paste0("Estimated mean: ", exp(fit$par[1]), "   Estimated SD: ", exp(fit$par[2]))) +
  xlab("LN[Size (nm)]") +
  ylab("Cumulative Concentration (particles/mL)")








fig2b <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2b_autodetectAll.csv",
                  header=F)

fig2b$V2[fig2b$V2 < 0] <- 0
fig2b <- arrange(fig2b, V1)
names(fig2b) <- c("x", "y")
plot(log(fig2b$x), fig2b$y)

fig2b$cumy <- cumsum(fig2b$y)
fig2b$cumy_rescale <- fig2b$cumy / max(fig2b$cumy)

plot(log(fig2b$x), fig2b$cumy_rescale)

#assuming the Fig2b data follow a normal distribution (log), fit a normal CDF
#minimize squared errors to estimate mean, sd
estNorm <- function(parms, x, y) {
  sum((y - pnorm(x, mean = parms[1], sd = parms[2]))^2)
}

fit <- optim(c(3, 2), 
             fn = estNorm, 
             x = log(fig2b$x), 
             y = fig2b$cumy_rescale)

fit
exp(fit$par[1]) #87
exp(fit$par[2]) #1.5

fig2b$fitted <- pnorm(log(fig2b$x), fit$par[1], fit$par[2])
plot(log(fig2b$x), fig2b$fitted)


theme_set(theme_bw())
ggplot(data = fig2b, aes(x = log(x), y = fig2b$cumy_rescale)) + geom_point(size = 3) +
  geom_line(data = fig2b, aes(x=log(x), y=fitted), size = 1, colour = "steelblue") +
  labs(main="Observed vs. Predicted Cumulative Distributions", 
       subtitle=paste0("Estimated mean: ", exp(fit$par[1]), "   Estimated SD: ", exp(fit$par[2]))) +
  xlab("LN[Size (nm)]") +
  ylab("Cumulative Concentration (particles/mL)")









#try fixing Fig2a mean at 37
#assuming the Fig2a data follow a normal distribution (log), fit a normal CDF
#minimize squared errors to estimate mean, sd
estNorm <- function(parms, x, y) {
  sum((y - pnorm(x, mean = log(37), sd = parms[1]))^2)
}

fit <- optim(c(2), 
             fn = estNorm, 
             x = log(fig2a$x), 
             y = fig2a$cumy_rescale)

fit
exp(fit$par[1]) #1.7

fig2a$fitted <- pnorm(log(fig2a$x), log(37), fit$par[1])
plot(log(fig2a$x), fig2a$fitted)


theme_set(theme_bw())
ggplot(data = fig2a, aes(x = log(x), y = fig2a$cumy_rescale)) + geom_point(size = 3) +
  geom_line(data = fig2a, aes(x=log(x), y=fitted), size = 1, colour = "steelblue")






#try fixing Fig2b mean at 83
#assuming the Fig2a data follow a normal distribution (log), fit a normal CDF
#minimize squared errors to estimate mean, sd
estNorm <- function(parms, x, y) {
  sum((y - pnorm(x, mean = log(83), sd = parms[1]))^2)
}

fit <- optim(c(2), 
             fn = estNorm, 
             x = log(fig2b$x), 
             y = fig2b$cumy_rescale)


exp(fit$par[1]) #1.7
