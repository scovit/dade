#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// To have the different events in the bank 

int main(int argc, char *argv[])
{
float BIN= 1;    //   number of fragments que contient la bin   
int NTF= 35913;  // nbre total de frag 

int thr_uncut=5;
int thr_loops=7;

int NBINS;
FILE* fic1 = NULL;FILE* fic01 = NULL;FILE* fic6 = NULL;
FILE* fic3 = NULL;FILE* fic5 = NULL;FILE* fic4 = NULL;
int chr1,chr2;
int locus1,locus2,locus;
int sens1,sens2,sens;
int mq1,mq2;
int match1,match2;
int indice1,indice2,indice;
int d1,d2;
int taille1, taille2;
int p;
int left,right;
int j=0,b=0,NPOS_repeat=0;
int i=0;
int c,c_a=0;
int label;
int n_int=0,n_intra=0,n_inter=0;

int *chro_ind;chro_ind = calloc (50000 , sizeof(int));

int   *tab_x;   tab_x  = calloc (100000 , sizeof(int));
float *tab_y;   tab_y  = calloc (100000 , sizeof(float));
int indice_x,indice_y;
int pas =10;

int *keep;    keep  = calloc (50000 , sizeof(int));
int *taille;   taille  = calloc (50000 , sizeof(int));
int *norm;   norm  = calloc (50000 , sizeof(int));
int taille_temp,ind;
char cmd[200];

fic01 = fopen(argv[1],"r");
if(!fic01) return 1;
char name1[300];strcpy(name1,argv[1]);
printf("File HiC used : %s\n",name1);

fic3 = fopen("config.dat","w");
fic4 = fopen("categories.dat","w");
fic5 = fopen("table.dat","w");
// fic6 = fopen("output.dat","w");

NBINS= (int) NTF/BIN;
printf("nombre de BINS %d\n",NBINS+1);
int num_chro1=0,num_chro2=0;

int nsites;
int noccurences[4][1000];

    for(i=0;i<1000 ;i++)	  
    {
    for(j=0;j<4;j++)	  
    {noccurences[j][i]=0;}   
    }

int *tab_weirds;tab_weirds = calloc (50000 , sizeof(int));
int *tab_loops;tab_loops = calloc (50000 , sizeof(int));
int *tab_uncut;tab_uncut = calloc (50000 , sizeof(int));
int *tab_lrange_intra;tab_lrange_intra = calloc (50000 , sizeof(int));
int *tab_lrange_inter;tab_lrange_inter = calloc (50000 , sizeof(int));

int n_mito=0; 
int n_mito_inter=0;
int n_mito_total=0;
int weirds=0,loops=0,uncuts=0,lrange_intra=0,lrange_inter=0;
// -----------------------------------------MATRICE INT CONSTRUCTION-------------------------------------------------------------------
// float** MAT_INT = malloc(50000*sizeof(float*));
// for(i=0;i<50000;i++){ MAT_INT[i] = malloc(50000*sizeof(float));}

j=0;
while(fscanf(fic01,"%d %d %d %d %d %d %d %d    %d %d %d %d %d %d %d %d",&chr1,&locus1,&sens1,&mq1,&match1,&indice1,&d1,&taille1,&chr2,&locus2,&sens2,&mq2,&match2,&indice2,&d2,&taille2) != EOF)
	      {
	      j++;
	      if(j % 1000000 == 0){printf("%d %d %d %d %d %d %d %d   %d %d %d %d %d %d %d\n",j,chr1,locus1,sens1,mq1,match1,indice1,d1,chr2,locus2,sens2,mq2,match2,indice2,d2);}

	      if(indice1 != 0 && indice2 != 0)
	      {	
	      chro_ind[indice1]=chr1;
	      chro_ind[indice2]=chr2;
	      
	      if(locus2 > locus1) {nsites= indice2 - indice1;} 
	      else {nsites = indice1 - indice2;sens=sens1;sens1=sens2;sens2=sens;} 
	      
	      if(chr1 == chr2) {n_intra++;}
	      if(chr1 != chr2) {n_inter++;}
	      
	      if(chr1 == chr2)
	      {
	      if(indice1 == indice2 && ( (sens1==0 && sens2==0)  ||  (sens1==16 && sens2==16) )  )   {weirds++;tab_weirds[indice1]++;tab_weirds[indice2]++;}
	      else if( nsites <= thr_loops && (sens1==16 && sens2==0))   {loops++;tab_loops[indice1]++;tab_loops[indice2]++;}
	      else if( nsites <= thr_uncut && (sens1==0 && sens2==16))   {uncuts++;tab_uncut[indice1]++;tab_uncut[indice2]++;}
	      else {tab_lrange_intra[indice1]++;tab_lrange_intra[indice2]++;lrange_intra++;}
	      }	
	      
	      if(chr1 != chr2)
	      {
	      tab_lrange_inter[indice1]++;tab_lrange_inter[indice2]++;lrange_inter++;
	      }
	            
	      if(nsites<500 && chr1 == chr2)
	      {	
	      if     (sens1 == 0 && sens2 == 0)	  {noccurences[0][nsites]++;}
	      else if(sens1 == 16 && sens2 == 16)       {noccurences[1][nsites]++;}
	      else if(sens1 == 0 && sens2 == 16)        {noccurences[2][nsites]++;}
	      else if(sens1 == 16 && sens2 == 0)	  {noccurences[3][nsites]++;}  
	      }
	      
	      if(chr1 ==17 ^ chr2 ==17)     {n_mito_inter++;}
	      if(chr1 ==17 || chr2 ==17)    {n_mito_total++;}
	      }

	      }
n_int = j;
printf("il y a %d interactions 3D du fichier HiC traité.\n",j);
fclose(fic01);
printf("MATRICE INT CONSTRUCTED\n");


// ----------------------------------------------------
//    AFFICHAGE CONFIG FOR DIGESTION ASSESSMENT    : 
// ----------------------------------------------------
	      for(i=0;i<1000 ;i++)	  
	      {
		fprintf(fic3,"%d\t",i);
		    for(j=0;j<4;j++)	  
		    { 
		    fprintf(fic3,"%d\t",noccurences[j][i]);
		    }
		fprintf(fic3,"%d \n",noccurences[0][i]+noccurences[1][i]+noccurences[2][i]+noccurences[3][i]);    
	      }
// ----------------------------------------------------


int boucle;
int uncut;
int weird;

boucle = noccurences[3][0]+noccurences[3][1]+noccurences[3][2]+noccurences[3][3]+noccurences[3][4]+noccurences[3][5];
uncut = noccurences[2][0]+noccurences[2][1]+noccurences[2][2]+noccurences[2][3]+noccurences[2][4]+noccurences[2][5]+noccurences[2][6]+noccurences[2][7];
weird = noccurences[0][0]+noccurences[1][0];

printf("intra = %d, inter = %d total = %d, inter_mito = %d\n",n_intra,n_inter,n_int, n_mito_inter );


printf("inter / total = %f\n",(float) n_inter/n_int);
printf("inter Mito / inter      = %f\n",(float) n_mito_inter / n_inter);
printf("inter Mito / mito_total = %f\n",(float) n_mito_inter / n_mito_total);

printf("lrange_intra = %d, lrange_inter = %d\n",lrange_intra,lrange_inter);

printf("boucles = %d, uncut = %d weird = %d \n", boucle,uncut,weird);
printf("boucles = %d, uncut = %d weird = %d \n", loops,uncuts,weirds);

printf("boucles = %f, uncut = %f weird = %f \n", (float) boucle/n_int,(float) uncut/n_int,(float) weird/n_int);
printf("boucles = %f, uncut = %f weird = %f \n", (float) boucle/n_intra,(float) uncut/n_intra,(float) weird/n_intra);
// printf("MATRICE INT NORMALISED CONSTRUCTED\n");      
// free(MAT_INT);

// fprintf(fic4,"%d\t%d\t%d\t%d\t%d\t%d\t%d\n",weird,boucle,uncut,lrange_intra,lrange_inter,n_mito,n_int);
fprintf(fic4,"%d\t%d\t%d\t%d\t%d\t%d\t%d\n",weirds,loops,uncuts,lrange_intra,lrange_inter,n_mito,n_int);

fclose(fic3);
fclose(fic4);

// ----------------------------------------------------
//    FILE TABLE   : 
// ----------------------------------------------------

for(j=1;j<=NTF;j++)	  
{ 
fprintf(fic5,"%d\t%d\t%d\t%d\t%d\t%d\n",j,tab_weirds[j],tab_loops[j],tab_uncut[j],tab_lrange_intra[j],tab_lrange_inter[j] );
}

fclose(fic5);


// ----------------------------------------------------
system("Rscript scr_config.R");
system("Rscript scr_categories.R");

sprintf(cmd, "rm -r -f %s.output",name1);
system(cmd);

sprintf(cmd, "mkdir %s.output",name1);
system(cmd);

sprintf(cmd, "mv categories.dat %s.output",name1);
system(cmd);
sprintf(cmd, "mv config.dat %s.output",name1);
system(cmd); 
sprintf(cmd, "mv table.dat %s.output",name1);
system(cmd); 

sprintf(cmd, "mv pie.png %s.output",name1);
system(cmd);
sprintf(cmd, "mv config.png %s.output",name1);
system(cmd); 
sprintf(cmd, "mv config2.png %s.output",name1);
system(cmd); 


return 0;
}





