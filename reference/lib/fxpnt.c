#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "fxpnt.h"

fxpnt_cfg_t *fxpnt_cfg(int8_t n_i, int8_t n_f) {
    fxpnt_cfg_t *data = calloc(1, sizeof(fxpnt_cfg_t));
    data->n_i = n_i;
    data->n_f = n_f;

    uint64_t ones = ~((fxpnt_t) 0);
    data->mask = ~(ones << (data->n_f + data->n_i));
    data->max_v = (fxpnt_t)(data->mask >> 1);
    data->min_v = ~data->max_v;

    data->mask_f = (1UL << data->n_f) - 1UL;
    data->mask_i = ((1UL << (data->n_i + data->n_f)) - 1) & ~(data->mask_f);

    return data;
}

fxpnt_cfg_t *fxpnt_cfg_clone(const fxpnt_cfg_t *cfg) {
    fxpnt_cfg_t *data = calloc(1, sizeof(fxpnt_cfg_t));
    data->n_i = cfg->n_i;
    data->n_f = cfg->n_f;

    data->mask = cfg->mask;
    data->max_v = cfg->max_v;
    data->min_v = cfg->min_v;
    data->mask_f = cfg->mask_f;
    data->mask_i = cfg->mask_i;

    return data;
}

void fxpnt_free(fxpnt_cfg_t *cfg) {
    free(cfg);
}

fxpnt_t fxpnt_mult(fxpnt_cfg_t *cfg, fxpnt_t a, fxpnt_t b) {
    bool sign_a = a < 0;
    bool sign_b = b < 0;

    if (sign_a)
        a = -a;
    if (sign_b)
        b = -b;

    bool sign = sign_a ^ sign_b;
    
    uint64_t a_i = FXPNT_INT(cfg, a);
    uint64_t a_f = FXPNT_FRAC(cfg, a);
    uint64_t b_i = FXPNT_INT(cfg, b);
    uint64_t b_f = FXPNT_FRAC(cfg, b);

    uint64_t z_f = (a_f * b_f >> cfg->n_f) + a_i * b_f + b_i * a_f;
    uint64_t z_i = a_i * b_i + (z_f >> cfg->n_f);

    fxpnt_t ret = fxpnt_new(cfg, z_i, z_f);
    return sign ? -ret : ret;
}

double fxpnt_to_double(fxpnt_cfg_t *cfg, fxpnt_t x) {
    return (double)((int64_t) x) / (1L << (cfg->n_f));
}

fxpnt_t fxpnt_from_int(fxpnt_cfg_t *cfg, int n) {
    return (fxpnt_t)(((int64_t) n) << cfg->n_f);
}

fxpnt_t fxpnt_from_double(fxpnt_cfg_t *cfg, double x) {
    return (fxpnt_t) (x * (1L << cfg->n_f));
}

fxpnt_t fxpnt_saturate(fxpnt_cfg_t *cfg, fxpnt_t x) {
    bool negative = (x & (1L << 63)) != 0;

    if (negative)
        return x < cfg->min_v ? cfg->min_v : x;
    return x > cfg->max_v ? cfg->max_v : x;
}

fxpnt_t fxpnt_new(fxpnt_cfg_t *cfg, int64_t i, uint64_t f) {
    uint64_t x = (f & cfg->mask_f) | ((i << cfg->n_f) & cfg->mask_i);
    return FXPNT_NEG(cfg, x) ? (~cfg->mask | x) : x;
}

fxpnt_t fxpnt_to_fxpnt(fxpnt_cfg_t *cfg, fxpnt_t x, fxpnt_cfg_t *to) {
    uint64_t i = FXPNT_INT(cfg, x);
    uint64_t f = FXPNT_FRAC(cfg, x);

    int8_t frac_diff = to->n_f - cfg->n_f;

    if (frac_diff > 0)
        f <<= frac_diff;
    else
        f >>= -frac_diff;
    
    return fxpnt_new(to, i, f);
}

