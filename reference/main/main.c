#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "xoroshiro128plus.h"
#include "fxpnt.h"
#include "fxpnt_piecewise_poly.h"

#include "main.h"

#define CONST_LN2 0.6931471805599453
#define CONST_SQRT2 1.4142135623730951

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

#define RIGHT_SHIFT(x, d) (((d) >= 0) ? ((x) >> (d)) : ((x) << -(d)))

static fxpnt_pp_t *log_pp;
static fxpnt_pp_t *sqrt_pp;
static fxpnt_pp_t *cos_pp;

static fxpnt_cfg_t *trig_cfg;

fxpnt_t fxpnt_sqrt2, fxpnt_ln2;

void setup(void) {
    fxpnt_cfg_t *cfg = fxpnt_cfg(8, 32);
    
    log_pp = fxpnt_pp_new(cfg, 4, 2); // 2^4 == 16 segments, degree 2
    memcpy(log_pp->table, FXPNT_PP_LOG, sizeof(FXPNT_PP_LOG));

    sqrt_pp = fxpnt_pp_new(cfg, 4, 2);
    memcpy(sqrt_pp->table, FXPNT_PP_SQRT, sizeof(FXPNT_PP_SQRT));

    cos_pp = fxpnt_pp_new(cfg, 4, 2);
    memcpy(cos_pp->table, FXPNT_PP_COS, sizeof(FXPNT_PP_COS));
    
    fxpnt_free(cfg);

    trig_cfg = fxpnt_cfg(8, 14);
    
    fxpnt_ln2 = fxpnt_from_double(log_pp->cfg, CONST_LN2);
    fxpnt_sqrt2 = fxpnt_from_double(sqrt_pp->cfg, CONST_SQRT2);
}

void teardown(void) {
    fxpnt_pp_free(log_pp);
    fxpnt_pp_free(sqrt_pp);
    fxpnt_pp_free(cos_pp);

    fxpnt_free(trig_cfg);
}

void gaussian(uint64_t rand, fxpnt_cfg_t *cfg, fxpnt_t *out) {
    uint64_t u_0 = 0xFFFFFFFFFFFFL & rand; // 48 bit uniform random
    uint64_t u_1 = 0xFFFFL & (rand >> 48); // 16 bit uniform random

    //
    // Operation: e = -2 * ln(u_0)  
    //
    
    // Calculate mantissa of u_0, with implicit leading 1-bit
    int exp_e = count_leading_zeros(48, u_0) + 1;
    uint64_t x_e = 0xFFFFFFFFFFFF & (u_0 << exp_e);

    // Shift "mantissa" to fill fraction
    x_e = x_e >> (48 - log_pp->cfg->n_f);

    // Evaluate mantissa ( \in [1,2) )
    fxpnt_t y_e = fxpnt_pp_eval(log_pp, x_e);
    // e = -2 ln(x) = 2 * (exp_e * ln(2) - ln(mantissa))
    fxpnt_t e = (fxpnt_ln2 * exp_e - y_e) << 1;

    //
    // Operation: f = sqrt(e)
    //

    // Convert if log_pp and sqrt_pp differ!
    if (log_pp->cfg->n_f != sqrt_pp->cfg->n_f)
        e = fxpnt_to_fxpnt(log_pp->cfg, e, sqrt_pp->cfg);

    // Range Reduction
    int exp_f = 5 - count_leading_zeros(6 + log_pp->cfg->n_f, e);
    fxpnt_t x_f = RIGHT_SHIFT(e, exp_f);

    // Evaluate sqrt(M_x) (Where M_x is [1,2))
    fxpnt_t y_f = fxpnt_pp_eval(sqrt_pp, x_f);

    if (exp_f & 1) // Compensate odd exponents
        y_f = fxpnt_mult(sqrt_pp->cfg, y_f, fxpnt_sqrt2);

    fxpnt_t f = RIGHT_SHIFT(y_f, -(exp_f>>1)); // Reconstruct range

    //
    // Operation: g_0 = sin(tau * u_1), g_1 = cos(tau * u_1)
    //

    int quad = (u_1 >> 14) & 0b11;
    fxpnt_t x_g = (fxpnt_t) (u_1 & 0x3fff);
    fxpnt_t x_g_i = (fxpnt_t)(trig_cfg->mask_f) - x_g;

    fxpnt_t y_g_a = fxpnt_pp_eval(cos_pp, fxpnt_to_fxpnt(trig_cfg, x_g, cos_pp->cfg));
    fxpnt_t y_g_b = fxpnt_pp_eval(cos_pp, fxpnt_to_fxpnt(trig_cfg, x_g_i, cos_pp->cfg));

    fxpnt_t g_0, g_1;
    switch (quad) {
    case 0:
        g_0 = y_g_b;
        g_1 = y_g_a;
        break;
    case 1:
        g_0 = y_g_a;
        g_1 = -y_g_b;
        break;
    case 2:
        g_0 = -y_g_b;
        g_1 = -y_g_a;
        break;
    case 3:
        g_0 = -y_g_a;
        g_1 = y_g_b;
        break;
    }
    
    out[0] = fxpnt_to_fxpnt(sqrt_pp->cfg, fxpnt_mult(cos_pp->cfg, f, g_0), cfg);
    out[1] = fxpnt_to_fxpnt(sqrt_pp->cfg, fxpnt_mult(cos_pp->cfg, f, g_1), cfg);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("%s: Not enough arguments!\n", argv[0]);
        printf("Usage: %s <OUTFILE> <MAX_ITERATIONS>\n", argv[0]);
        return 1;
    }
    
    FILE *outfile = fopen(argv[1], "wb");
    if (!outfile && errno) {
        printf("%s: Failed to open output file: %s\n", argv[0], strerror(errno));
        return EXIT_FAILURE;
    }

    int max_iterations;
    if (sscanf(argv[2], "%d", &max_iterations) < 1) {
        printf("%s: Invalid argument, failed to interpret \"%s\" as int!\n", argv[0], argv[2]);
        return EXIT_FAILURE;
    }
    
    xoroshiro128plus_t xoro;
    xoroshiro128plus_init(&xoro, 0xcafebabe8badbeef);

    setup();

    fxpnt_cfg_t *cfg = fxpnt_cfg(8, 32);
    fxpnt_t gaussians[2];

    double buffer[1024];

    for (int i = 0; i < max_iterations; i++) {
        for (size_t j = 0; j < (sizeof(buffer) / sizeof(*buffer));) {
            uint64_t u = xoroshiro128plus_next(&xoro);
            gaussian(u, cfg, gaussians);
            
            buffer[j++] = fxpnt_to_double(cfg, gaussians[0]);
            buffer[j++] = fxpnt_to_double(cfg, gaussians[1]);
        }

        for (size_t w = 0; w < sizeof(buffer) / sizeof(*buffer);)
            w += fwrite(buffer, sizeof(*buffer), sizeof(buffer)/sizeof(*buffer) - w, outfile);
    }
    
    fclose(outfile);

    teardown();
    fxpnt_free(cfg);
    
    return 0;
}
