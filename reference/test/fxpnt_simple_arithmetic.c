#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <check.h>

#include <fxpnt.h>

static fxpnt_cfg_t *cfg;

void setup(void) {
    cfg = fxpnt_cfg(8, 16);
}

void teardown(void) {
    fxpnt_free(cfg);
}

START_TEST(test_fxpnt_int_add) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, 15);
    
    ck_assert(a + b == y);
}
END_TEST

START_TEST(test_fxpnt_int_sub) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, 5);
    
    ck_assert(b - a == y);
    ck_assert(b - a == a);
}
END_TEST

START_TEST(test_fxpnt_int_mult) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 6);
    fxpnt_t y = fxpnt_from_int(cfg, 30);

    ck_assert(fxpnt_mult(cfg, a, b) == y);
}
END_TEST

START_TEST(test_fxpnt_neg_int_sub) {
    fxpnt_t a = fxpnt_from_int(cfg, 5);
    fxpnt_t b = fxpnt_from_int(cfg, 10);
    fxpnt_t y = fxpnt_from_int(cfg, -5);

    ck_assert(a - b == y);
    ck_assert(fxpnt_to_double(cfg, y) == -5.0);
}
END_TEST

START_TEST(test_fxpnt_neg_int_mult) {
    fxpnt_t a = fxpnt_from_int(cfg, -5);
    fxpnt_t b = fxpnt_from_int(cfg, -10);
    fxpnt_t c = fxpnt_from_int(cfg, 5);

    fxpnt_t y = fxpnt_from_int(cfg, 50);
    fxpnt_t z = fxpnt_from_int(cfg, -50);
    
    ck_assert(fxpnt_mult(cfg, a, b) == y);
    ck_assert(fxpnt_mult(cfg, b, c) == z);
}
END_TEST

START_TEST(test_fxpnt_double_conversion) {
    double values[] = {0.125, 1.6, 3.125, 9524, -5.6, -0.001, 3.141592653589793};

    for (size_t i = 0; i < sizeof(values)/sizeof(*values); i++)
        ck_assert_double_eq_tol(fxpnt_to_double(cfg, fxpnt_from_double(cfg, values[i])), values[i], 1.0 / (1 << cfg->n_f));
}
END_TEST

Suite *make_fxpnt_arith_suite(void) {
    Suite *s;
    TCase *tc_core;

    s = suite_create("Fixed Point Simple Arithmetic Suite");
    tc_core = tcase_create("Test Cases with Setup and Teardown");

    tcase_add_checked_fixture(tc_core, setup, teardown);

    tcase_add_test(tc_core, test_fxpnt_int_add);
    tcase_add_test(tc_core, test_fxpnt_int_sub);
    tcase_add_test(tc_core, test_fxpnt_int_mult);

    tcase_add_test(tc_core, test_fxpnt_neg_int_sub);
    tcase_add_test(tc_core, test_fxpnt_neg_int_mult);
    
    tcase_add_test(tc_core, test_fxpnt_double_conversion);

    suite_add_tcase(s, tc_core);

    return s;
}

int main(void) {
    int number_failed = 0;
    SRunner *sr = srunner_create(make_fxpnt_arith_suite());
    srunner_set_fork_status(sr, CK_NOFORK);
    srunner_set_log(sr, "test.log");
    srunner_run_all(sr, CK_VERBOSE);

    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
