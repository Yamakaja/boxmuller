#include <stdint.h>
#include <stdlib.h>
#include <check.h>

#include <fxpnt.h>

static fxpnt_cfg_t *cfg;
static fxpnt_cfg_t *alt_cfg;

void setup(void) {
    cfg = fxpnt_cfg(8, 16);
    alt_cfg = fxpnt_cfg(16, 8);
}

void teardown(void) {
    fxpnt_free(cfg);
    fxpnt_free(alt_cfg);
}

START_TEST(test_fxpnt_min_max) {
    ck_assert_int_eq(cfg->min_v, -0x800000);
    ck_assert_int_eq(cfg->max_v, 0x7FFFFFL);

    ck_assert_int_eq(cfg->mask, 0xFFFFFFUL);
    ck_assert_int_eq(cfg->mask_f, 0xFFFFUL);
    ck_assert_int_eq(cfg->mask_i, 0xFF0000UL);
}
END_TEST

START_TEST(test_fxpnt_macros) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, -5);
    fxpnt_t c = fxpnt_from_double(cfg, 1.125);

    ck_assert_int_eq(FXPNT_INT(cfg, a), 5);
    ck_assert_int_eq(FXPNT_FRAC(cfg, a), 0);

    ck_assert_int_eq(FXPNT_INT(cfg, b), -5);
    ck_assert_int_eq(FXPNT_FRAC(cfg, b), 0);

    ck_assert_int_eq(FXPNT_INT(cfg, c), 1);
    ck_assert_int_eq(FXPNT_FRAC(cfg, c), 8192);

    ck_assert(!FXPNT_NEG(cfg, a));
    ck_assert(FXPNT_NEG(cfg, b));
    ck_assert(!FXPNT_NEG(cfg, c));
}
END_TEST

START_TEST(test_fxpnt_to_fxpnt) {
    fxpnt_t a = fxpnt_from_double(cfg, 42.125);
    fxpnt_t b = fxpnt_from_double(alt_cfg, 42.125);

    fxpnt_t c = fxpnt_from_double(cfg, -42.125);
    fxpnt_t d = fxpnt_from_double(alt_cfg, 42.125);

    ck_assert_int_eq(fxpnt_to_fxpnt(cfg, a, alt_cfg), b);
    ck_assert_int_eq(fxpnt_to_fxpnt(alt_cfg, b, cfg), a);

    ck_assert_int_eq(fxpnt_to_fxpnt(cfg, -c, alt_cfg), d);
    ck_assert_int_eq(fxpnt_to_fxpnt(alt_cfg, -d, cfg), c);
}
END_TEST

START_TEST(test_fxpnt_int_add) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, 15);
    
    ck_assert_int_eq(a + b, y);
}
END_TEST

START_TEST(test_fxpnt_int_sub) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, 5);
    
    ck_assert_int_eq(b - a, y);
    ck_assert_int_eq(b - a, a);
}
END_TEST

START_TEST(test_fxpnt_int_mult) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 6);
    fxpnt_t y = fxpnt_from_int(cfg, 30);

    ck_assert_int_eq(fxpnt_mult(cfg, a, b), y);
}
END_TEST

START_TEST(test_fxpnt_neg_int_sub) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, -5);

    ck_assert_int_eq(a - b, y);
    ck_assert_double_eq(fxpnt_to_double(cfg, y), -5.0);
}
END_TEST

START_TEST(test_fxpnt_neg_int_mult) {
    fxpnt_t a = fxpnt_from_int(cfg, -5);
    fxpnt_t b = fxpnt_from_int(cfg, -10);
    fxpnt_t c = fxpnt_from_int(cfg, 5);

    fxpnt_t y = fxpnt_from_int(cfg, 50);
    fxpnt_t z = fxpnt_from_int(cfg, -50);
    
    ck_assert_int_eq(fxpnt_mult(cfg, a, b), y);
    ck_assert_int_eq(fxpnt_mult(cfg, b, c), z);
}
END_TEST

START_TEST(test_fxpnt_double_conversion) {
    double values[] = {0.125, 1.6, 3.125, 9524, -5.6, -0.001, 3.141592653589793};

    for (size_t i = 0; i < sizeof(values)/sizeof(*values); i++)
        ck_assert_double_eq_tol(fxpnt_to_double(cfg, fxpnt_from_double(cfg, values[i])), values[i], 1.0 / (1 << cfg->n_f));
}
END_TEST

START_TEST(test_fxpnt_saturation) {
    fxpnt_t a = fxpnt_from_int(cfg, 100);
    
    ck_assert_int_eq(fxpnt_saturate(cfg, a + a), cfg->max_v);
    ck_assert_int_eq(fxpnt_saturate(cfg, -(a + a)), cfg->min_v);
}
END_TEST

Suite *make_fxpnt_arith_suite(void) {
    Suite *s;
    TCase *tc_core;

    s = suite_create("Fixed Point Simple Arithmetic Suite");
    tc_core = tcase_create("Test Cases");

    tcase_add_checked_fixture(tc_core, setup, teardown);

    tcase_add_test(tc_core, test_fxpnt_min_max);
    tcase_add_test(tc_core, test_fxpnt_macros);
    tcase_add_test(tc_core, test_fxpnt_to_fxpnt);

    tcase_add_test(tc_core, test_fxpnt_int_add);
    tcase_add_test(tc_core, test_fxpnt_int_sub);
    tcase_add_test(tc_core, test_fxpnt_int_mult);

    tcase_add_test(tc_core, test_fxpnt_neg_int_sub);
    tcase_add_test(tc_core, test_fxpnt_neg_int_mult);
    
    tcase_add_test(tc_core, test_fxpnt_double_conversion);
    tcase_add_test(tc_core, test_fxpnt_saturation);

    suite_add_tcase(s, tc_core);

    return s;
}

int main(void) {
    int number_failed = 0;
    SRunner *sr = srunner_create(make_fxpnt_arith_suite());
    srunner_set_fork_status(sr, CK_NOFORK);
    srunner_set_log(sr, "test_fxpnt.log");
    srunner_run_all(sr, CK_VERBOSE);

    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
