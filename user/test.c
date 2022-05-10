#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char** argv){

    
    fork();
    //fork();
    printf("%d\n", cpu_process_count(0));
   
    exit(0);


}