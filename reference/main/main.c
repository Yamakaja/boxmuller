#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "xoroshiro128plus.h"
#include "fxpnt.h"
#include "fxpnt_piecewise_poly.h"

#include "main.h"

#define CONST_LN2 0.6931471805599453

int count_leading_zeros(int len, uint64_t x) {
    uint64_t mask = 1UL << (len - 1);
    for (int i = 0; i < len; ++i) {
        if (x & mask)
            return i;
        else
            mask >>= 1;
    }
    return len;
}

static fxpnt_pp_t *log_pp;

void setup_pp_tables(void) {
    fxpnt_cfg_t *cfg = fxpnt_cfg(8, 32);
    
    log_pp = fxpnt_pp_new(cfg, 7, 2); // 2^7 == 128 segments, degree 2
    memcpy(log_pp->table, FXPNT_PP_LOG, sizeof(FXPNT_PP_LOG));
    
    fxpnt_free(cfg);
}

void teardown_pp_tables(void) {
    fxpnt_pp_free(log_pp);
}

void gaussian(uint64_t rand, fxpnt_cfg_t *cfg, fxpnt_t *out) {
    uint64_t u_0 = 0xFFFFFFFFFFFF & rand; // 48 bit uniform random
    uint64_t u_1 = 0xFFFF & (rand >> 48); // 16 bit uniform random

    //
    // Operation: e = -2 * ln(u_0)  
    //
    
    // Calculate mantissa of u_0, with implicit leading 1-bit
    int exp_e = count_leading_zeros(48, u_0) + 1;
    uint64_t x_e = 0xFFFFFFFFFFFF & (u_0 << exp_e);

    // Shift "mantissa" to fill fraction
    x_e = x_e >> (48 - log_pp->cfg->n_f);

    const fxpnt_t fxpnt_ln2 = fxpnt_from_double(log_pp->cfg, CONST_LN2);

    // Evaluate mantissa ( \in [1,2) )
    fxpnt_t y_e = fxpnt_pp_eval(log_pp, x_e);
    // e = -2 ln(x) = 2 * (exp_e * ln(2) - ln(mantissa))
    fxpnt_t e = (fxpnt_ln2 * exp_e - y_e) << 1;

    // printf("%f\n", fxpnt_to_double(log_pp->cfg, e));

    // TODO: Continue ...
    
    out[0] = fxpnt_from_int(cfg, 0);
    out[1] = fxpnt_from_int(cfg, 0);
}

int main(void) {
    xoroshiro128plus_t xoro;
    xoroshiro128plus_init(&xoro, 0xcafebabe8badbeef);

    // printf("xoroshiro128plus: Seeds: (0x%016lx, 0x%016lx)\n", xoro.s[1], xoro.s[0]);

    setup_pp_tables();

    fxpnt_cfg_t *cfg = fxpnt_cfg(8, 16);
    fxpnt_t gaussians[2];
    
    gaussian(xoroshiro128plus_next(&xoro), cfg, gaussians);

    teardown_pp_tables();
    fxpnt_free(cfg);
    
    return 0;
}
