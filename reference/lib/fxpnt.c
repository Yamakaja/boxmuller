#include <stdint.h>
#include <stdlib.h>

#include "fxpnt.h"

fxpnt_cfg_t *fxpnt_cfg(int8_t n_i, int8_t n_f) {
    fxpnt_cfg_t *data = calloc(1, sizeof(fxpnt_cfg_t));
    data->n_i = n_i;
    data->n_f = n_f;
    return data;
}

void fxpnt_free(fxpnt_cfg_t *cfg) {
    free(cfg);
}

fxpnt_t fxpnt_mult(fxpnt_cfg_t *cfg, fxpnt_t a, fxpnt_t b) {
    return (a * b) >> (cfg->n_f);
}

double fxpnt_to_double(fxpnt_cfg_t *cfg, fxpnt_t x) {
    return (double)((int64_t) x) / (1 << (cfg->n_f));
}

fxpnt_t fxpnt_from_int(fxpnt_cfg_t *cfg, int n) {
    return (fxpnt_t)(((int64_t) n) << cfg->n_f);
}

fxpnt_t fxpnt_from_double(fxpnt_cfg_t *cfg, double x) {
    return (fxpnt_t) (x * (1 << cfg->n_f));
}
