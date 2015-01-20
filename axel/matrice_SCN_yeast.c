#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// remove uncut,loops
// remove poor interacting fragments
// make bins of 10 detectable frags
// yeast : with some improvements notably the bins with two different chromosomes
//  changement des elements de la trace qui etaient comptes deux fois ... 

int main(int argc, char *argv[])
{
float BIN= 10;    //   number of fragments que contient la bin  
int seuil_min= -1;  //  seuil de reads pour qu'un frag soit dit detectable 

int NTF= 50000;

int th_uncut= 3;
int th_loop=  1;
int th_weirds = 1;

int th_int = 50;

int NBINS;
FILE* fic1 = NULL;FILE* fic01 = NULL;FILE* fic2 = NULL;
FILE* fic3 = NULL;FILE* fic4 = NULL; FILE* fic5 = NULL;FILE* fic11 = NULL;
int chr1,chr2;
int locus1,locus2,locus;
int sens1,sens2,sens;
int mq1,mq2;
int match1,match2;
int indice,indice1,indice2;
int taille1,taille2;
int d1,d2;
int p;
int left,right;
int j=0,b=0,NPOS_repeat=0;
unsigned int i=1;
int c,c_a=0;
int label;
long int IND_REPEAT[80000];
long int IND_RANDOM[80000];
int * chro_ind;
chro_ind = calloc (80000, sizeof(int));
char type_repeat[100];
char type_repeat_avant[100];
strcpy(type_repeat, "INIT");strcpy(type_repeat_avant, "INIT");
unsigned int chr1_repeat,position_repeat,indice_repeat;
int NBIN_repeat=0;
int *tab_left;   tab_left  = calloc (80000 , sizeof(int));
int *tab_right;  tab_right  = calloc (80000 , sizeof(int));
int *pos1_bin;   pos1_bin  = calloc (80000 , sizeof(int));
int *pos2_bin;   pos2_bin  = calloc (80000, sizeof(int));
char cmd[300];
float keep[80000];
int nsites;

fic01 = fopen(argv[1],"r");
if(!fic01) return 1;
printf("File HiC used : %s\n",argv[1]);

fic2 = fopen("mat_temp.dat","w");    
fic3 = fopen("hist_temp.dat","w");
fic4 = fopen("hist_temp2.dat","w");
fic5 = fopen("frags.txt","w");

NBINS= (int) NTF/BIN;
printf("nombre de BINS %d\n",NBINS+1);

// -----------------------------------------MATRICE INT CONSTRUCTION-------------------------------------------------------------------
int sum0[80000];int sum1[80000];int sum2[80000];int sum3[80000];int sum4[80000];int sum5[80000];
int indice_bin[80000];
float norm[80000];
int jj=0;

int** tab_pos_indice = malloc(17*sizeof(int*));
tab_pos_indice[0]= malloc(5000000	*sizeof(int));
tab_pos_indice[1]= malloc(5000000	*sizeof(int));
tab_pos_indice[2]= malloc(5000000	*sizeof(int));
tab_pos_indice[3]= malloc(5000000	*sizeof(int));
tab_pos_indice[4]= malloc(5000000	*sizeof(int));
tab_pos_indice[5]= malloc(5000000	*sizeof(int));
tab_pos_indice[6]= malloc(5000000	*sizeof(int));
tab_pos_indice[7]= malloc(5000000	*sizeof(int));
tab_pos_indice[8]= malloc(5000000	*sizeof(int));
tab_pos_indice[9]= malloc(5000000	*sizeof(int));
tab_pos_indice[10]=malloc(5000000	*sizeof(int));
tab_pos_indice[11]=malloc(5000000	*sizeof(int));
tab_pos_indice[12]=malloc(5000000	*sizeof(int));
tab_pos_indice[13]=malloc(5000000	*sizeof(int));
tab_pos_indice[14]=malloc(5000000	*sizeof(int));
tab_pos_indice[15]=malloc(5000000	*sizeof(int));
tab_pos_indice[16]=malloc(5000000      *sizeof(int));

int** MAT_INT = malloc(80000*sizeof(int*));
for(i=0;i<80000;i++){ MAT_INT[i] = malloc(80000*sizeof(int));}

int** MAT_RAW = malloc(80000*sizeof(int*));
for(i=0;i<80000;i++){ MAT_RAW[i] = malloc(80000*sizeof(int));}

int** MAT_RAW2 = malloc(80000*sizeof(int*));
for(i=0;i<80000;i++){ MAT_RAW2[i] = malloc(80000*sizeof(int));}

// fic11 = fopen("/data/yeasts_species_project/castelli/fragments_list.dat6","r");
fic11 = fopen(argv[2],"r");
if(!fic11) return 1;
j=0;
	      while(fscanf(fic11,"%d %d %d",&c,&left,&right) != EOF)
	      {       
	      j++;  //indice du frag 
	      tab_left[j]=left;
	      tab_right[j]=right;
	      
		for(p=left;p<=right;p++)
		{
		tab_pos_indice[c-1][p-1] = j;
		}
	      chro_ind[j]=c;	  
	      }
fclose(fic11);
printf("ALL chromosomes in stock with %d frag.\n",j);


j=0;
while(fscanf(fic01,"%d %d %d %d %d %d %d %d   %d %d %d %d %d %d %d %d",&chr1,&locus1,&sens1,&mq1,&match1,&indice1,&d1,&taille1,&chr2,&locus2,&sens2,&mq2,&match2,&indice2,&d2,&taille2) != EOF)
{
j++;
if(j % 1000000 == 0){printf("%d %d %d %d %d %d %d %d %d %d %d %d %d\n",j,chr1,locus1,sens1,match1,indice1,d1,chr2,locus2,sens2,match2,indice2,d2);}

if(chr1 != chr2)
{ 
if(indice2 < indice1) {sens=sens1;sens1=sens2;sens2=sens;locus=locus1;locus1=locus2;locus2=locus;indice=indice1;indice1=indice2;indice2=indice;} 
nsites=indice2-indice1;

sum0[indice1]++;
sum0[indice2]++;

MAT_RAW[indice1][indice2]++;
MAT_RAW[indice2][indice1]++;

		  if     (sens1 == 0  && sens2 == 0 && nsites<1)                  {sum1[indice1]++;sum1[indice2]++;}  //  ++  weirds
		  else if(sens1 == 16 && sens2 == 16 && nsites <1)                {sum2[indice1]++;sum2[indice2]++;}  //  --  weirds
		  else if(sens1 == 0  && sens2 == 16 && nsites < th_uncut)        {sum3[indice1]++;sum3[indice2]++;}  //  +-  uncut
		  else if(sens1 == 16 && sens2 == 0 && nsites < th_loop)	  {sum4[indice1]++;sum4[indice2]++;}  //  -+  loops
		  else {sum5[indice1]++;sum5[indice2]++;}
}
}
printf("There are %d interactions 3D from the HiC file processed.\n",j);
fclose(fic01);

// -----------------------------------------------------------------------------
//   Histo of number of reads: all reads, weirds ++,weirds--,uncuts, loops, long range for every frags to remove poor frags 
for(i=1;i<=NTF;i++)
{
if(chro_ind[i] > 0) {fprintf(fic3,"%d %d %d %d %d %d %d\n",i,sum0[i],sum1[i],sum2[i],sum3[i],sum4[i],sum5[i] );  }
}  

//   Histo des interactions to remove too strong ones 
for(i=1;i<=NTF;i++)
{
    for(j=1;j<=NTF;j++)
    {  
    if(MAT_RAW[i][j] > 0 && chro_ind[i] != chro_ind[j] ) fprintf(fic4,"%d\n",MAT_RAW[i][j]);  
    }		
}  

// ----------------------------------
//  Binnage with bins containing 10 detectables fragments 
int i_frag=0;
int detect;
int comp=0;
int n_bins=0;
indice = 1;

 for(i=1;i<= NTF;i++)
  {
  
  if(chro_ind[i] > 0)
  {  
  if(chro_ind[i] != chro_ind[i-1] && i>1 && comp!=0 ) {indice = indice +1;comp=0;}
  
  if( sum0[i] > seuil_min  )  
  {detect=1;i_frag++;comp++; indice_bin[i] = indice; if(comp==BIN && chro_ind[i+60] > 0 ) {indice = indice +1;comp=0;}  } 
  
  else 
  {detect=0;indice_bin[i] = -1;}
  
  fprintf(fic5,"%d %d %d %d %d %d   %d %d %d %d %d %d\n",i,detect,chro_ind[i],tab_left[i],tab_right[i],indice_bin[i], sum0[i],sum1[i],sum2[i],sum3[i],sum4[i],sum5[i]); 
  }
  } 

n_bins = indice; 
printf("There are %d detectable fragments that we put in %d.\n",i_frag,n_bins);

// -----------------------------------------------------------------------------
fic01 = fopen(argv[1],"r");
if(!fic01) return 1; 
j=0;
	    while(fscanf(fic01,"%d %d %d %d %d %d %d %d   %d %d %d %d %d %d %d %d",&chr1,&locus1,&sens1,&mq1,&match1,&indice1,&d1,&taille1,&chr2,&locus2,&sens2,&mq2,&match2,&indice2,&d2,&taille2) != EOF)
	    {
	    j++;
	    if(j % 1000000 == 0){printf("%d %d %d %d %d %d %d %d %d %d %d %d %d\n",j,chr1,locus1,sens1,match1,indice1,d1,chr2,locus2,sens2,match2,indice2,d2);}

// 	    if(chr1 != chr2=)
// 	    if(j <= 32913729)
	    {  
            if(indice2 < indice1) {sens=sens1;sens1=sens2;sens2=sens;locus=locus1;locus1=locus2;locus2=locus;indice=indice1;indice1=indice2;indice2=indice;} 
	    nsites=indice2-indice1;
	     
			      if(indice1 >=0 &&  indice2 >=0 )
			      {	
			      if     (sens1 == 0 && sens2 == 0 && nsites   >= th_weirds)     {indice1 = indice_bin[indice1];indice2 = indice_bin[indice2];if(indice1 != indice2) {MAT_INT[indice1][indice2]++;MAT_INT[indice2][indice1]++;} else{MAT_INT[indice1][indice2]++;}}  //  ++
			      else if(sens1 == 16 && sens2 == 16 && nsites >= th_weirds)   {indice1 = indice_bin[indice1];indice2 = indice_bin[indice2];if(indice1 != indice2) {MAT_INT[indice1][indice2]++;MAT_INT[indice2][indice1]++;} else{MAT_INT[indice1][indice2]++;}}  //  --      
			      else if(sens1 == 0 && sens2 == 16 && nsites  >= th_uncut)    {indice1 = indice_bin[indice1];indice2 = indice_bin[indice2];if(indice1 != indice2) {MAT_INT[indice1][indice2]++;MAT_INT[indice2][indice1]++;} else{MAT_INT[indice1][indice2]++;}}  //  +-
			      else if(sens1 == 16 && sens2 == 0 && nsites  >= th_loop)	    {indice1 = indice_bin[indice1];indice2 = indice_bin[indice2];if(indice1 != indice2) {MAT_INT[indice1][indice2]++;MAT_INT[indice2][indice1]++;} else{MAT_INT[indice1][indice2]++;}}  //  -+
			      }  
	 		      
	    }
	    }
printf("There are %d interactions 3D du fichier HiC traité.\n",j);
fclose(fic01);

// ----------------------------------------------------
//    RAW MATRICE OR LIST: 
// ----------------------------------------------------

	      for(i=1;i<=n_bins;i++)	  
	      {
		for(j=1;j<=n_bins;j++)	  
		{
	        fprintf(fic2,"%d\t",MAT_INT[i][j]);
		}
	      fprintf(fic2,"\n");
	      }

free(MAT_INT);
fclose(fic2);
fclose(fic3);

// sprintf(cmd, "matlab -nodesktop -nosplash -r "oct_blur11;quit;"");
// system(" matlab -nodesktop -nosplash -r "oct_blur11;quit;" "); 
// system("matlab -nodesktop -nosplash -r oct_blur11");

// sprintf(cmd, "mkdir %s",argv[3]);
// system(cmd); 
// 
// sprintf(cmd, "mv matt* %s",argv[3]);
// system(cmd); 


return 0;
}
