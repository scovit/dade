#!/usr/bin/env Rscript
library(grid)
library(RColorBrewer)
library(lattice)
library(latticeExtra)

args <- commandArgs(trailingOnly = TRUE);
if (length(args) != 1) {
    write("Usage: ./drawmatrix.R colors < matrix > pdffile\nSample colors:\n'#00007F blue #007FFF cyan #7FFF7F yellow #FF7F00 red #7F0000'\nquotes are important!!", stderr());
    quit(status=-1);
}
qw <- function(x) unlist(strsplit(x, "[[:space:]]+"))
userPallette <- qw(args[1]);

pdf(file="/dev/stdout", width= 8.3, height = 8.3)
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

m <- read.updiag("/dev/stdin");
#labe <- sapply(strsplit(rownames(m), '~'), function (x) {paste(x[4])})
labe <- sapply(strsplit(rownames(m), '~'), function (x) {paste(x[4])})
#sp1 <- (which(labe>719756))[[1]]
#sp2 <- (which(labe>849206))[[1]]
nele <- length(labe)
labereal <- labe[round(pretty(1:nele)+1)];
labeat <- round(pretty(1:nele)+1);
#labereal <- labe[sort(c(sp1, sp2, round(pretty(1:nele)+1)))];
#labeat <- sort(c(sp1, sp2, round(pretty(1:nele)+1)));
#labereal <- labe[c(sp1,sp2)];
#labeat <- c(sp1,sp2);
m <- (m + t(as.matrix(m)) + 1);
#m <- m/sum(m);
m <- log(m)/log(10);
pushViewport(viewport(layout.pos.col = 1, layout.pos.row = 1))
print(levelplot(m, xlab = NULL, ylab = NULL,
                par.settings=list(layout.heights=list(top.padding=-3,
                                      bottom.padding=-1)),
                col.regions = colorRampPalette(userPallette)(100),
                ## col.regions = colorRampPalette(c("#7F0000", "red", 
                ##     "#FF7F00", "yellow",
                ##     "#7FFF7F", "yellow",
                ##     "#FF7F00", "red", "#7F0000"))(100),
                ## gray(0:100/100),
                panel = panel.levelplot.raster,
                ## interpolate=TRUE,
                scales=list(
                    y=list(alternating=1,
                        labels=labereal,
                        at=labeat),
                    x=list(alternating=1,
                        labels=labereal,
                        at=labeat)
                    )
                ), newpage = FALSE)
## grid.text(fname, x=unit(0.5,"npc"), y=unit(0.03,"npc"),
##           gp=gpar(col="darkred", fontsize=14));
popViewport()
popViewport()
garbage <- dev.off();

quit();
