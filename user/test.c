#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char** argv){

    
    
    sleep(2);
    printf("cpu 1 is %d\n", cpu_process_count(0));
    printf("cpu 2 is %d\n", cpu_process_count(1));
    printf("cpu 3 is %d\n", cpu_process_count(2));
    exit(0);


}