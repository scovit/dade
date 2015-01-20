#   script R pour faire la fig des proportions des configs 

#png("config.png")

d=read.table('config.dat')

plot(d$V1,d$V2/sum(d$V2+d$V3+d$V4+d$V5)*100,col="red",type="b",main="Different configurations of the interactions (% of the total of int)",log="y",xlim=c(0,20),ylim=c(5e-05,100),pch=19,xlab="N sites",ylab="% of the reads")
points(d$V1,d$V3/sum(d$V2+d$V3+d$V4+d$V5)*100,col="green",type="b",pch=19)
points(d$V1,d$V4/sum(d$V2+d$V3+d$V4+d$V5)*100,col="blue",type="b",pch=19)
points(d$V1,d$V5/sum(d$V2+d$V3+d$V4+d$V5)*100,col="pink",type="b",pch=19)


points(17,90,col="red",pch=19)
text(18,90,"++",col="red")

points(17,9,col="green",pch=19)
text(18,9,"--",col="green")

points(17,0.9,col="blue",pch=19)
text(18,0.9,"+-",col="blue")

points(17,0.09,col="pink",pch=19)
text(18,0.09,"-+",col="pink")

dev.off();



png("config2.png")

d=read.table('config.dat')

plot(d$V1,d$V2/d$V6*100,col="red",type="b",main="Different configurations of the interactions (% in the nsites cat)",log="y",xlim=c(0,20),ylim=c(5e-05,100),pch=19,xlab="N sites",ylab="% of the reads")
points(d$V1,d$V3/d$V6*100,col="green",type="b",pch=19)
points(d$V1,d$V4/d$V6*100,col="blue",type="b",pch=19)
points(d$V1,d$V5/d$V6*100,col="pink",type="b",pch=19)


points(17,90,col="red",pch=19)
text(18,90,"++",col="red")

points(17,9,col="green",pch=19)
text(18,9,"--",col="green")

points(17,0.9,col="blue",pch=19)
text(18,0.9,"+-",col="blue")

points(17,0.09,col="pink",pch=19)
text(18,0.09,"-+",col="pink")

#dev.off();






