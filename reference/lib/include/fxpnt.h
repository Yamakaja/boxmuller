#ifndef H_FXPNT
#define H_FXPNT

typedef int64_t fxpnt_t;
typedef struct fxpnt_cfg_t {
    int8_t n_i;
    int8_t n_f;
} fxpnt_cfg_t;

fxpnt_cfg_t *fxpnt_cfg(int8_t n_i, int8_t n_f);

void fxpnt_free(fxpnt_cfg_t *cfg);

fxpnt_t fxpnt_from_int(fxpnt_cfg_t *, int n);

fxpnt_t fxpnt_mult(fxpnt_cfg_t *, fxpnt_t a, fxpnt_t b);

double fxpnt_to_double(fxpnt_cfg_t *, fxpnt_t x);

fxpnt_t fxpnt_from_double(fxpnt_cfg_t *, double x);

#define FXPNT_FRAC(CFG, X) ((X) & ((1 << (CFG)->n_f) - 1))
#define FXPNT_INT(CFG, X) ((X) >> ((CFG)->n_f))

#endif
