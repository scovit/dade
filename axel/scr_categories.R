# script R to make pie diagram about the different categories 


data=read.table("categories.dat")

weirds=data[1,1];
loops=data[1,2];
uncut=data[1,3];
long_intra=data[1,4];
long_inter=data[1,5];
mito=data[1,6];
total=data[1,7];

slices <- c(weirds,loops,uncut,long_intra,long_inter)
lbls <- c("Weirds","Loops","Uncut","Long Range Intra", "Long Range Inter")
pct <- round(slices/sum(slices)*100);
lbls <- paste(lbls, pct) # add percents to labels 
lbls <- paste(lbls,"%",sep="") # ad % to labels 
png(filename="pie.png", height=600, width=700, bg="white")
pie(slices, labels = lbls, main="Pie Chart of different events")

r1=long_inter/total;
r2=mito/long_inter;

text(-1.2,1,c("long_inter/total ") );text(-0.7,1.0,r1);
text(-1,0.9,c("long_inter"));text(-0.7,0.9,long_inter);

text(-0.2,1.0,c("mito/long_inter") );text(0.3,1.0,r2); 
text(-0.08,0.9,c("Mito_inter"));text(0.35,0.9,mito);

text(1.0,1,c("Total number of aligned pairs") );
text(1.0,0.9,total);

text(-1.0,-1.0,c("INTER / (INTRA+INTER)") );
text(-0.35,-1.0,long_inter/(long_intra+long_inter) );

text(-0.95,-1.06,c("Total of Long range interactions:") );
text(-0.35,-1.06,long_intra+long_inter );


dev.off()
