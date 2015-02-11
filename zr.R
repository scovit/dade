library(grid)
library(lattice)

pdf(file = "zdynamics.pdf", width= 8.3, height = 8.3)
ncol <- 2
nrow <- 3
pushViewport(viewport(layout = grid.layout(nrow = nrow, ncol = ncol)))

zlim=10

GROUP <- "local_equispacedG"

N <- 256
SIGMA <- 0.0427611758752
E <- 0.1
EPNT <- 3.4 - E
PNT <- "unif.8.pnt"
INCFG <- "globuleN256S0.0427611758752.in"

TIME <- 3
dynamult <- 3
plots=NULL
for(j in 1:6) {
  m <- matrix(scan(paste(GROUP,
                         N,
                         SIGMA,
                         E,
                         EPNT,
                         PNT,
                         INCFG,
                         TIME,
                         ".dist.gz",
                         sep="~")), byrow=T, ncol=256)
  pushViewport(viewport(layout.pos.col = ((j - 1) %% ncol) + 1,
                        layout.pos.row = floor((j - 1) / ncol) + 1))
  print(((j - 1) %% ncol) + 1)
  print(floor((j - 1) / ncol) + 1)
  print(levelplot(m, xlab = NULL, ylab = NULL, zlim = zlim,
                  par.settings=list(layout.heights=list(top.padding=-3,
                                      bottom.padding=-1))
                  ), newpage = FALSE)
  grid.text(paste("time = ", TIME), x=unit(0.88,"npc"), y=unit(0.09,"npc"),
            gp=gpar(col="darkred", fontsize=14));
  popViewport()

  TIME <- TIME * dynamult
}

popViewport()
dev.off()
