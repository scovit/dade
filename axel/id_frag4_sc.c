#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//  prog pour avoir les d1 et indice du frag de chaque mapping 

int main(int argc, char *argv[])
{
FILE* fic1 = NULL;
FILE* fic2 = NULL;
FILE* fic3 = NULL;

int chr1,chr2;
int locus1,locus2;
int sens1,sens2;
int mq1,mq2;
int match1,match2;
int indice1,indice2;
int d1,d2;
int taille1, taille2;
int p;
int left,right;
int j=0;
unsigned int i=0;
int c,c_a=0;
int tab_left[35915];
int tab_right[35915];

int** tab_pos_indice = malloc(17*sizeof(int*));

tab_pos_indice[0]= malloc(230218	*sizeof(int));
tab_pos_indice[1]= malloc(813184	*sizeof(int));
tab_pos_indice[2]= malloc(316620	*sizeof(int));
tab_pos_indice[3]= malloc(1531933	*sizeof(int));
tab_pos_indice[4]= malloc(576874	*sizeof(int));
tab_pos_indice[5]= malloc(270161	*sizeof(int));
tab_pos_indice[6]= malloc(1090940	*sizeof(int));
tab_pos_indice[7]= malloc(562643	*sizeof(int));
tab_pos_indice[8]= malloc(439888	*sizeof(int));
tab_pos_indice[9]= malloc(745751	*sizeof(int));
tab_pos_indice[10]=malloc(666816	*sizeof(int));
tab_pos_indice[11]=malloc(1078177	*sizeof(int));
tab_pos_indice[12]=malloc(924431	*sizeof(int));
tab_pos_indice[13]=malloc(784333	*sizeof(int));
tab_pos_indice[14]=malloc(1091291	*sizeof(int));
tab_pos_indice[15]=malloc(948066	*sizeof(int));
tab_pos_indice[16]=malloc(85779        *sizeof(int));

fic1 = fopen("/home/axel/Bureau/python/scripts_scere/dpnii_sc.dat24","r");
if(!fic1) return 1;
j=0;
	      while(fscanf(fic1,"%d %d %d",&c,&left,&right) != EOF)
	      {       
	      j++;  //indice du frag 
	      tab_left[j]=left;
	      tab_right[j]=right;
	      
		for(p=left;p<=right;p++)
		{
		tab_pos_indice[c-1][p-1] = j;
		}
		if(c!=c_a && c_a!=0){printf("%d  %d\n",c-1,j-1);}
		c_a=c;
	      }
fclose(fic1);
printf("ALL chromosomes in stock  avec %d frag.\n",j);

//----------------------------------------------------------------------------------------
printf("file input : %s\n", argv[1]);
fic2 = fopen(argv[1], "r");

fic3 = fopen(strcat(argv[1],".ind3"), "w");
j=0;

// while(fscanf(fic2,"%d %d %d %d %d %d %d   %d %d %d %d %d %d %d",&chr1,&locus1,&sens1,&mq1,&match1,&indice1,&d1,&chr2,&locus2,&sens2,&mq2,&match2,&indice2,&d2) != EOF)
while(fscanf(fic2,"%d %d %d  %d %d %d %d %d\n",&chr1,&locus1,&sens1,&chr2,&locus2,&sens2,&indice1,&indice2) != EOF)  
{
		      j++;
		      
		      match1=130;
		      match2=130;
		      
		      // correction pour les négatifs car le logiciel de mapping donne la borne inférieure en position absolue : 
		      if(sens1 == 16) {locus1=locus1+ match1-1;}  //position mapping corrigé pour les - 
		      if(sens2 == 16) {locus2=locus2+ match2-1;}  //position mapping corrigé pour les - 

		      if(tab_pos_indice[chr1-1][locus1-1] >0 ) {indice1 = tab_pos_indice[chr1-1][locus1-1];}
		      if(tab_pos_indice[chr2-1][locus2-1] >0 ) {indice2 = tab_pos_indice[chr2-1][locus2-1];}
		      
		      taille1 = tab_right[indice1] - tab_left[indice1];
		      taille2 = tab_right[indice2] - tab_left[indice2];

		      // distances aux mapping :
			  if(tab_pos_indice[chr1-1][locus1-1] >0 ) 
			  {
		    
			  { 	
			  if(sens1 == 0) {d1=tab_right[indice1]-locus1;}
			  else  	     {d1=locus1-tab_left[indice1];}
			  }

// 			  while( d1 < 90)
// 			  { 
// 			  if(sens1 == 0) {indice1=indice1+1;d1=tab_right[indice1]-locus1;}
// 			  else  	     {indice1=indice1-1;d1=locus1-tab_left[indice1];}
// 			  }
			  
			  }

			if(tab_pos_indice[chr2-1][locus2-1] >0 ) 
			{
			  
			{  
			if(sens2 == 0) {d2=tab_right[indice2]-locus2;}
			else  	     {d2=locus2-tab_left[indice2];}
			}
			
// 			while(d2 < 90)
// 			{  
// 			if(sens2 == 0) {indice2=indice2+1;d2=tab_right[indice2]-locus2;}
// 			else  	     {indice2=indice2-1;d2=locus2-tab_left[indice2];}
// 			}
			
			}
		      
if(j % 1000000 == 0){printf("%d\n",j);printf("%d\t%d\t%d\t%d\t%d\t%d\t%d\t\t\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",chr1,locus1,sens1,mq1,match1,indice1,d1,chr2,locus2,sens2,mq2,match2,indice2,d2);}  

fprintf(fic3,"%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t\t\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",chr1,locus1,sens1,mq1,match1,indice1,d1,taille1,chr2,locus2,sens2,mq2,match2,indice2,d2,taille2);  
}

printf("il y a %d interactions 3D du fichier HiC traité.\n",j);
fclose(fic2);
fclose(fic3);

return 0;
}
