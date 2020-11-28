#include <stdint.h>
#include <stdlib.h>
#include <check.h>

#include <xoroshiro128plus.h>

xoroshiro128plus_t xoro_state;

void setup(void) {
}

void teardown(void) {
}

START_TEST(test_splitmix64) {
    xoro_state.x = 0xcafebabe8badbeef;

    ck_assert_int_eq(splitmix64_next(&xoro_state), 0x4a235bb2c0c27de7);
    ck_assert_int_eq(splitmix64_next(&xoro_state), 0x29efb6c812624816);
}
END_TEST

START_TEST(test_xoroshiro128plus) {
    xoro_state.x = 0xcafebabe8badbeef;

    xoro_state.s[0] = splitmix64_next(&xoro_state);
    xoro_state.s[1] = splitmix64_next(&xoro_state);

    uint64_t values[] = {
        0x7413127ad324c5fd,
        0x907dbbd379b8c604,
        0xbdd25f287853407c,
        0x40a7fdf35d30280f,
        0x9c10f58cb718b148,
        0x240822d2c3a39a4d,
        0xc4c6684e95f05ec4,
        0x5b0abc668b71422b,
        0xb5ff5e9d4bc953a7,
        0xba3493bf5fd65da1
    };

    for (size_t i = 0; i < sizeof(values) / sizeof(*values); i++)
        ck_assert_int_eq(xoroshiro128plus_next(&xoro_state), values[i]);
}

Suite *make_xoroshiro128plus_suite(void) {
    Suite *s;
    TCase *tc_core;

    s = suite_create("Xoroshiro128plus Test Suite");
    tc_core = tcase_create("Test Cases");

    tcase_add_checked_fixture(tc_core, setup, teardown);

    tcase_add_test(tc_core, test_splitmix64);
    tcase_add_test(tc_core, test_xoroshiro128plus);

    suite_add_tcase(s, tc_core);

    return s;
}

int main(void) {
    int number_failed = 0;
    SRunner *sr = srunner_create(make_xoroshiro128plus_suite());
    srunner_set_fork_status(sr, CK_NOFORK);
    srunner_set_log(sr, "test_xoroshiro128plus.log");
    srunner_run_all(sr, CK_VERBOSE);

    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
