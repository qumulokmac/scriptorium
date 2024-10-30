#include <fstream>
#include <iostream>
#include <stdio.h>
#include <string>
using namespace std;

int main(int argc, char *argv[]) {

if (argc!=2) { printf("Wrong input!\n"); return EXIT_FAILURE; }

ofstream myfile;
char fileNameOut[200];
ifstream f;
float floatName;
int i;
const char * extension = ".dat";
char * str = new char[30];

strncpy(fileNameOut, argv[1], strlen(argv[1])-4);
strcpy (fileNameOut+strlen(argv[1])-4, extension);
myfile.open (fileNameOut);

printf ("\nOpening file \"%s\"...\n", argv[1]);
f.open (argv[1], ios::binary);
if (f==NULL){
printf("Cannot open file!\n\n");
return 1; }
else{
while (! f.eof()){
f.read ( (char*)(&floatName), sizeof(floatName));

sprintf (str, "%f", floatName);

myfile << str << "\n";

}
}
delete [] str;
myfile.close(); f.close();
return 0;
}

