#!/usr/bin/env Rscript
library(grid)
library(RColorBrewer)
library(lattice)
library(latticeExtra)

args <- commandArgs(trailingOnly = TRUE);
if (length(args) != 3) {
    write("Usage: ./drawmatrix.R matrix1 matrix2 pdffile", stderr());
    quit(status=-1);
}
fname1=args[1];
fname2=args[2];
fpdf=args[3];

pdf(file=fpdf, width= 8.3, height = 8.3)
pushViewport(viewport(layout = grid.layout(nrow = 1, ncol = 1)))

read.updiag <- function (file) {
    a <- read.table(file, header = TRUE, row.names=1,fill=1);
    cnames <- colnames(a);
    a <- t(apply(cbind(1:(dim(a)[1]), a)
               , 1
               , function(v) {
                   c(rep(0,v[1]-1), v[2:(length(v)-v[1]+1)])
               })
           );
    colnames(a) <- cnames;
    a
}

m1 <- read.updiag(fname1)
m2 <- read.updiag(fname2)

#labe <- sapply(strsplit(rownames(m1), '~'), function (x) {paste(x[4])})
labe <- sapply(strsplit(rownames(m1), '~'), function (x) {paste(x[1])})
nele <- length(labe)
m1 <- (m1 + t(as.matrix(m1)) + 1)
m1 <- m1/sum(m1)
m2 <- (m2 + t(as.matrix(m2)) + 1)
m2 <- m2/sum(m2)

m <- log(m2/m1);
pushViewport(viewport(layout.pos.col = 1, layout.pos.row = 1))
print(levelplot(m, xlab = NULL, ylab = NULL,
                par.settings=list(layout.heights=list(top.padding=-3,
                                      bottom.padding=-1)),
                col.regions = colorRampPalette(c("#00007F", "blue", 
                    "white", "white",
                    "red", "#7F0000"))(100),
                ## col.regions = colorRampPalette(c("#00007F", "blue",
                ##     "#007FFF", "cyan",
                ##     "#7FFF7F", "yellow",
                ##     "#FF7F00", "red", "#7F0000"))(100),
                ## col.regions = colorRampPalette(c("#7F0000", "red", 
                ##     "#FF7F00", "yellow",
                ##     "#7FFF7F", "yellow",
                ##     "#FF7F00", "red", "#7F0000"))(100),
                ## gray(0:100/100),
                panel = panel.levelplot.raster,
                ## interpolate=TRUE,
                scales=list(
                    y=list(alternating=1,
                        labels=labe[round(pretty(1:nele)+1)],
                        at=pretty(1:nele)+1),
                    x=list(alternating=1,
                        labels=labe[round(pretty(1:nele)+1)],
                        at=pretty(1:nele)+1)
                    )
                ), newpage = FALSE)
## grid.text(fname, x=unit(0.5,"npc"), y=unit(0.03,"npc"),
##           gp=gpar(col="darkred", fontsize=14));
popViewport()
popViewport()
dev.off()

quit();
