#include <stdio.h>
#include <string.h>

int main()
{
    int num1[200], num2[200];
    int result[400];
    char c_num1[200], c_num2[200];

    scanf("%s", c_num1);
    scanf("%s", c_num2);

    int len1 = strlen(c_num1);
    for(int i=0; i<len1; ++i) 
        num1[i] = c_num1[len1-i-1] - '0';
    
    int len2 = strlen(c_num2);
    for(int i=0; i<len2; ++i) 
        num2[i] = c_num2[len2-i-1] - '0';

    for(int i=0; i<400; ++i)
        result[i] = 0;

    for(int i=0; i<len1; ++i) {
        for(int j=0; j<len2; ++j) {
            result[i+j] += num1[i] * num2[j];
            result[i+j+1] += result[i+j] / 10;
            result[i+j] %= 10;
        }
    }

    int first = len1+len2;
    while(result[first] == 0) first--;
    for(int i=first; i>=0; i--)
        printf("%d", result[i]);
    printf("\n");
    return 0;
}