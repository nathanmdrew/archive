#set color palette for the Technical Report (TR)

# maroon 128 63 65
# blue 3 87 161
# teal 12 170 174
# navy 0 51 98
# slate 71 67 64
# turq 46 197 244
# dk org 190 83 37
# org 244 125 41
# purple 89 75 160
# grey 124 125 129

TR_colors = list(
  TR_palette = c(rgb(128,63,65, names="tr_maroon", maxColorValue=255),
                 rgb(3,87,161, names="tr_blue", maxColorValue=255),
                 rgb(12,170,174, names="tr_teal", maxColorValue=255),
                 rgb(0,51,98, names="tr_navy", maxColorValue=255),
                 rgb(71,67,64, names="tr_slate", maxColorValue=255),
                 rgb(46,197,244, names="tr_turquoise", maxColorValue=255),
                 rgb(190,83,37, names="tr_darkorange", maxColorValue=255),
                 rgb(244,125,41, names="tr_orange", maxColorValue=255),
                 rgb(89,75,160, names="tr_purple", maxColorValue=255),
                 rgb(124,125,129, names="tr_grey", maxColorValue=255))
)

rgb

cvi_palettes = function(name, n, all_palettes = cvi_colours, type = c("discrete", "continuous")) {
  palette = all_palettes[[name]]
  if (missing(n)) {
    n = length(palette)
  }
  type = match.arg(type)
  out = switch(type,
               continuous = grDevices::colorRampPalette(palette)(n),
               discrete = palette[1:n]
  )
  structure(out, name = name, class = "palette")
}

cvi_palettes("TR_palette", type = "discrete")



library("ggplot2")
df = data.frame(x = c("A", "B", "C"),
                y = 1:3)
g = ggplot(data = df,
           mapping = aes(x = x, y = y)) +
  theme_minimal() +
  theme(legend.position = c(0.05, 0.95),
        legend.justification = c(0, 1),
        legend.title = element_blank(), 
        axis.title = element_blank())

g + geom_col(aes(fill = x), colour = "black", size = 2) + ggtitle("Fill")
g + geom_col(aes(colour = x), fill = "white", size = 2) + ggtitle("Colour")

scale_colour_cvi_d = function(name) {
  ggplot2::scale_colour_manual(values = cvi_palettes(name,
                                                     type = "discrete"))
}

scale_fill_cvi_d = function(name) {
  ggplot2::scale_fill_manual(values = cvi_palettes(name,
                                                   type = "discrete"))
}


g +
  geom_col(aes(fill = x), size = 3) +
  scale_fill_cvi_d("TR_palette")
