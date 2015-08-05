#!/usr/bin/env Rscript

#  Prog to make Fisher test along two matrices
#  apply qvalues
#  add parralelisation

library('grid');
library('RColorBrewer');
library('lattice');
library('latticeExtra');
library('qvalue');
library('parallel');
#       library('fields');
#	library('pbapply');

args <- commandArgs(trailingOnly = TRUE);
if (length(args) != 3) {
    write("Usage: ./drawdiffmatrix.R matrix1 matrix2 pdffile", stderr());
    quit(status=-1);
}
fname1 <- args[1];
fname2 <- args[2];
fpdf   <- args[3];
ncpus  <- 16;
userPallette <- c("black", "green", "yellow", "red");


# Thresholds
significant <- 0.0005;
maxqval <- 0.000001;

# Load Matrices

write("Loading matrices", stderr())

# To load in .mat format

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

# To load in simple tabular format

# m1 <- read.table(fname1)
# m2 <- read.table(fname2)

# Parse the labels in the table

labe <- sapply(strsplit(rownames(m1), '~'), function (x) {paste(x[1])})
nele <- length(labe)

# Convert to simple matrix format

m1 <- m1 + t(as.matrix(m1))
m2 <- m2 + t(as.matrix(m2))
# m1 <- as.matrix(m1);
# m2 <- as.matrix(m2);

# Calculate row sums

sum1 <- matrix(rowSums(m1),nrow=nrow(m1),ncol=ncol(m1));
sum2 <- matrix(rowSums(m2),nrow=nrow(m2),ncol=ncol(m2));

# Calculate fisher text inputs

v <- cbind(as.vector(m1), as.vector(m2),
           as.vector(sum1-m1), as.vector(sum2-m2));
v <- as.data.frame(v);

# Calculate the fisher test in parallel environment

write("Calculationg fisher tests", stderr())

# Set up the parallel environment
clus <- makeCluster(ncpus)

# Calculate it
Sys.time()
pvals <- matrix(
   parRapply(clus,v,function(x) fisher.test(matrix(x,nrow=2))$p.value),
   nrow=nrow(m1)
);
Sys.time()

# Conversion of pvalues into qvalues

pvals[pvals>1] = 1;

qobj <- qvalue(pvals);
qval <- qobj$qvalues;
#qval <- apply(pvals, 1, function(x) qvalue(x)$qvalues);

# Thresholds application
qval[qval >= significant] = 1;
qval[qval < maxqval] = maxqval;

# Print the output

pdf(file=fpdf, width= 8.3, height = 8.3)
pushViewport(viewport(layout = grid.layout(nrow = 1, ncol = 1)))
pushViewport(viewport(layout.pos.col = 1, layout.pos.row = 1))

print(levelplot(-log10(qval), xlab = NULL, ylab = NULL,
                par.settings=list(layout.heights=list(top.padding=-3,
                                      bottom.padding=-1)),
                col.regions = colorRampPalette(userPallette)(100),
                ## col.regions = colorRampPalette(c("#00007F", "blue", 
                ##    "white",
                ##    "red", "#7F0000"))(100),
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
garbage <- dev.off()

quit();
