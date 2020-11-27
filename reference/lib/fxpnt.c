#include <stdint.h>

#include "fxpnt.h"

fxpnt_cfg_t fxpnt_cfg(int8_t n_i, int8_t n_f) {
    fxpnt_cfg_t data = {
        .n_i = n_i,
        .n_f = n_f
    };
    return data;
}

fxpnt_t fxpnt_mult(fxpnt_cfg_t *cfg, fxpnt_t a, fxpnt_t b) {
    return (a * b) >> (cfg->n_f);
}

double fxpnt_to_double(fxpnt_cfg_t *cfg, fxpnt_t x) {
    return (double)((int64_t) x) / (1 << (cfg->n_f));
}

fxpnt_t fxpnt_from_int(fxpnt_cfg_t *cfg, int n) {
    const fxpnt_t zero = 0;
    fxpnt_t x = (n << cfg->n_f);
    return x;
}
