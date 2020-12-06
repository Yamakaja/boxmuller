#ifndef H_FXPNT_PIECEWISE_POLY
#define H_FXPNT_PIECEWISE_POLY

typedef struct fxpnt_pp_t {
    fxpnt_cfg_t *cfg;
    size_t n;
    int log2_n;
    int degree;
    fxpnt_t *table;
} fxpnt_pp_t;

/*
 * Ownership of cfg is _not_ taken!
 */
fxpnt_pp_t *fxpnt_pp_new(const fxpnt_cfg_t *cfg, int log2_n, size_t degree);

void fxpnt_pp_free(fxpnt_pp_t *pp);

fxpnt_t *fxpnt_pp_get_seg(fxpnt_pp_t *pp, size_t n);

fxpnt_t fxpnt_pp_eval(fxpnt_pp_t *pp, fxpnt_t x);

#endif
