#include <stdio.h>
#include <stdint.h>

static inline unsigned clz(uint32_t x)
{
    int n = 32, c = 16;
    do {
        uint32_t y = x >> c;
        if (y) {
            n -= c;
            x = y;
        }
        c >>= 1;
    } while (c);
    return n - x;
}

int smallestNumber(int n) {
    int bit_len = (1 << (32-clz(n)))-1;
    
    return bit_len;
}

int main()
{
    int input[] = {1, 509, 1000}, output;
    int ans[] = {1, 511, 1023};

    for (int i = 0 ; i < 3 ; ++i)
    {
        output = smallestNumber(input[i]);


        printf("output = %d, answer = %d\n", output, ans[i]);
        
        if (output == ans[i])
            printf("True\n");
        else
            printf("False\n");

    }

    return 0;
}
