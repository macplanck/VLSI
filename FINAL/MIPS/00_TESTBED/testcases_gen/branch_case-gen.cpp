#include <iostream>
#include <time.h>

#define PATTERN 32
#define TYPE    5


using namespace std;

FILE *CASE_FILE = fopen("branch_test.txt", "w");


char OP_BRANCH[TYPE][100000] = {"011001", "011010", "011100", "011101", "011110"};


int main() {

    srand(time(NULL));

    for(int i=0; i<PATTERN; i++) {
        fprintf(CASE_FILE, "%s", OP_BRANCH[rand() % TYPE]);
        for(int i=0; i<26; i++) fprintf(CASE_FILE, "%d", rand() % 2);
        fprintf(CASE_FILE, "\n");
    }

    return 0;

}
