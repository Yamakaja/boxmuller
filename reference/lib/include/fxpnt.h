#ifndef H_FXPNT
#define H_FXPNT

typedef int64_t fxpnt_t;
typedef struct fxpnt_cfg_t {
    int8_t n_i;
    int8_t n_f;
    fxpnt_t max_v;
    fxpnt_t min_v;
    uint64_t mask;
    uint64_t mask_i;
    uint64_t mask_f;
} fxpnt_cfg_t;

fxpnt_cfg_t *fxpnt_cfg(int8_t n_i, int8_t n_f);

fxpnt_cfg_t *fxpnt_cfg_clone(const fxpnt_cfg_t *cfg);

void fxpnt_free(fxpnt_cfg_t *cfg);

fxpnt_t fxpnt_from_int(fxpnt_cfg_t *, int n);

fxpnt_t fxpnt_mult(fxpnt_cfg_t *, fxpnt_t a, fxpnt_t b);

double fxpnt_to_double(fxpnt_cfg_t *, fxpnt_t x);

fxpnt_t fxpnt_from_double(fxpnt_cfg_t *, double x);

fxpnt_t fxpnt_saturate(fxpnt_cfg_t *, fxpnt_t x);

fxpnt_t fxpnt_new(fxpnt_cfg_t *, int64_t i, uint64_t f);

fxpnt_t fxpnt_to_fxpnt(fxpnt_cfg_t *, fxpnt_t, fxpnt_cfg_t *);

#define FXPNT_FRAC(CFG, X) ((uint64_t)((X) & ((1UL << (CFG)->n_f) - 1)))
#define FXPNT_INT(CFG, X) ((int64_t)((X) >> ((CFG)->n_f)))
#define FXPNT_NEG(CFG, X) (((X) >> ((CFG)->n_f + (CFG)->n_i - 1)) != 0)

#endif
