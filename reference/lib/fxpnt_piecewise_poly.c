#include <stdint.h>
#include <stdlib.h>
#include <fxpnt.h>
#include <fxpnt_piecewise_poly.h>

fxpnt_pp_t *fxpnt_pp_new(const fxpnt_cfg_t *cfg, int log2_n, size_t degree) {
    fxpnt_pp_t *pp = calloc(1, sizeof(fxpnt_pp_t));
    pp->cfg = fxpnt_cfg_clone(cfg);
    pp->log2_n = log2_n;
    pp->n = 1UL << log2_n;
    pp->degree = degree;
    pp->table = calloc(pp->n * (degree + 1), sizeof(fxpnt_t));

    return pp;
}

void fxpnt_pp_free(fxpnt_pp_t *pp) {
    free(pp->table);
    pp->table = NULL;
    
    fxpnt_free(pp->cfg);
    pp->cfg = NULL;
    free(pp);
    pp = NULL;
}

fxpnt_t *fxpnt_pp_get_seg(fxpnt_pp_t *pp, size_t n) {
    return &(pp->table[n * (pp->degree + 1)]);
}

fxpnt_t fxpnt_pp_eval(fxpnt_pp_t *pp, fxpnt_t x) {
    uint64_t frac = FXPNT_FRAC(pp->cfg, x);
    size_t section_idx = frac >> (pp->cfg->n_f - pp->log2_n);

    fxpnt_t *section = fxpnt_pp_get_seg(pp, section_idx);
    fxpnt_t sum = 0;

    fxpnt_t x_power = fxpnt_from_int(pp->cfg, 1);

    int n_bits = pp->cfg->n_f - pp->log2_n;
    fxpnt_t mask = ~(fxpnt_t)((~0UL) << n_bits);
    x = x & mask;
    
    for (int i = 0; i <= pp->degree; i++) {
        sum += fxpnt_mult(pp->cfg, section[i], x_power);
        x_power = fxpnt_mult(pp->cfg, x_power, x);
    }

    return fxpnt_saturate(pp->cfg, sum);
}
