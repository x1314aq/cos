/**
 * @file: sign.c
 * @description: make **binary** file bootable
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>


int main(int argc, char *argv[])
{
    struct stat st;
    if (argc != 2) {
        fprintf(stderr, "Usage: sign FILE\n");
        return 1;
    }
    if (stat(argv[1], &st) != 0) {
        fprintf(stderr, "Error opening file %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
    printf("%s size: %lld bytes\n", argv[1], (long long)st.st_size);
    if (st.st_size > 510) {
        fprintf(stderr, "%lld >> 510!!\n", (long long)st.st_size);
        return 1;
    }
    unsigned char buf[512] = {0};
    FILE *fp = fopen(argv[1], "rb+");
    int size = fread(buf, 1, st.st_size, fp);
    if (size != st.st_size) {
        fprintf(stderr, "fread error, expected: %lld, but actually read: %d\n", st.st_size, size);
        return 1;
    }
    buf[510] = 0x55;
    buf[511] = 0xAA;
    rewind(fp);
    size = fwrite(buf, 1, 512, fp);
    if (size != 512) {
        fprintf(stderr, "fwrite error, %d bytes has been writed\n", size);
        return 1;
    }
    fclose(fp);
    printf("%s successfully signed!\n", argv[1]);
    return 0;
}
