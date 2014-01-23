#!/usr/bin/tcc -run

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    printf("Content-Type: text/html\n\n");
    printf("<title>Hello C Version</title>");
    printf("<h1 style='text-align: center; color: #880000;'>Hello, C World!</h1>");
    char *qs = getenv("QUERY_STRING");
    if (qs && (strlen(qs) > 0)) {
	printf("<p>QUERY STRING: <strong>%s</strong></p>", qs);
    }
    else {
	printf("<p>No QUERY STRING ;-(</p>");
    }

    char input[256];
    scanf("%s", input);
    printf("<p>STDIN: <strong>%s</strong></p>", input);
    
    return 0;
}

