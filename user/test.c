#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char** argv){

    int pid;
    int i;
    for (i=0;i<1;i++){
        pid = fork();
        printf("pid is %d\n", pid);
    }

    exit(0);


}