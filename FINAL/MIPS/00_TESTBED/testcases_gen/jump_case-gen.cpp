#include <iostream>
#include <time.h>

#define PATTERN 32

using namespace std;

FILE *CASE_FILE = fopen("test.txt", "w");


void JAL_gen() {

    fprintf(CASE_FILE, "001111");
    for(int i=0; i<26; i++) fprintf(CASE_FILE, "%d", rand() % 2);
    fprintf(CASE_FILE, "\n");

}


void JR_gen() {

    fprintf(CASE_FILE, "000000");
    for(int i=0; i< 5; i++) fprintf(CASE_FILE, "%d", rand() % 2);
    for(int i=0; i<15; i++) fprintf(CASE_FILE, "0");
    fprintf(CASE_FILE, "000001");
    fprintf(CASE_FILE, "\n");

}


int main() {

    srand(time(NULL));

    for(int i=0; i<PATTERN; i++) {
        if(rand() % 2) JAL_gen();
        else           JR_gen();
    }

    return 0;

}
