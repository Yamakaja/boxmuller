#include <stdio.h>
#include <stdint.h>

#include "fxpnt.h"

int main(void) {
    fxpnt_cfg_t cfg = fxpnt_cfg(8, 16);
    fxpnt_t x = fxpnt_from_int(&cfg, 5);
    
    printf("%f\n", fxpnt_to_double(&cfg, x));
}
