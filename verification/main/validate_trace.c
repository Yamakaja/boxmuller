#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <math.h>

#include "vcd.h"

#define MAX(a,b) ((a) > (b) ? (a) : (b))

int lzd(uint64_t x, int len) {
    x = x << (64 - len);
    int i = 0;
    for (; i < len; i++)
        if (x & (1UL << 63))
            break;
        else
            x <<= 1;

    return i;
}

void gaussian(uint64_t u_0, uint64_t u_1, uint64_t u_2, double *out) {
	double exp_e = lzd(u_0, 48) + 1.0;
    double e = 2 * (log(2.0) * exp_e - log(1.0+u_2*4.656612873077393e-10));

    double f = sqrt(e);

    out[0] = sin(2*M_PI * u_1 * 1.52587890625e-05) * f;
    out[1] = cos(2*M_PI * u_1 * 1.52587890625e-05) * f;
}

double signed_to_double(uint64_t x, int width) {
    int64_t x_ = x;
    int64_t sign_bit = 1L << (width - 1);
    int64_t extended_bits = ~((1 << width) - 1);

    return (x_ & sign_bit) ? (x_ | extended_bits) : (x_);
}

int main(int argc, char *argv[]) {
    if (argc == 1) {
        fprintf(stderr, "%s: Missing input file\n", argv[0]);
        fprintf(stderr, "Usage: %s <DUMP.VCD>\n", argv[0]);
        return EXIT_FAILURE;
    }

    vcd_t *vcd = vcd_open(argv[1], 5);
    if (vcd == NULL) {
        perror("Failed to open input file");
        return EXIT_FAILURE;
    }

    vcd_parse_header(vcd);

    puts("Signals:");
    for (int i = 0; i < vcd->signal_count; i++)
        printf(" * %s, width=%d, symbol=%c\n",
               vcd->signals[i].name, vcd->signals[i].width, vcd->signals[i].symbol);

    vcd_signal_t *r_i_u_0 = vcd_get_signal_by_name(vcd, "r_i_u_0");
    vcd_signal_t *r_i_u_1 = vcd_get_signal_by_name(vcd, "r_i_u_1");
    vcd_signal_t *r_i_u_2 = vcd_get_signal_by_name(vcd, "r_i_u_2");
    vcd_signal_t *t_x_0 = vcd_get_signal_by_name(vcd, "t_x_0");
    vcd_signal_t *t_x_1 = vcd_get_signal_by_name(vcd, "t_x_1");

    puts("");

    if (r_i_u_0 == NULL || r_i_u_1 == NULL || r_i_u_2 == NULL || t_x_0 == NULL || t_x_1 == NULL) {
        fprintf(stderr, "%s: Failed to acquire one or more required signals. "
                        "The required signals are: [r_i_u_0, r_i_u_1, r_i_u_2, t_x_0, t_x_1]\n",
                        argv[0]);
        return EXIT_FAILURE;
    }

    vcd_skip(vcd, 30);

    while (vcd_has_next(vcd)) {
        vcd_next(vcd);

        ssize_t i = vcd_get_data_idx(vcd, 0);
        ssize_t i_u_0 = vcd_get_data_idx(vcd, -21);
        ssize_t i_u_1 = vcd_get_data_idx(vcd, -6);
        ssize_t i_u_2 = vcd_get_data_idx(vcd, -29);

        double x[2];
        gaussian(r_i_u_0->data[i_u_0], r_i_u_1->data[i_u_1], r_i_u_2->data[i_u_2], x);

        double x_[2] = { signed_to_double(t_x_0->data[i], t_x_0->width) * 0.00048828125, signed_to_double(t_x_1->data[i], t_x_1->width) * .00048828125 };

        printf("%8.5f x_0=(%8.5f | %8.5f) x_1=(%8.5f | %8.5f) t=%12ld r_i_u_0=0x%016lx r_i_u_1=0x%016lx r_i_u_2=0x%016lx\n",
            fabs(MAX(x[0] - x_[0], x[1] - x_[1])),
            x[0], x_[0], x[1], x_[1],
            vcd->time,
            r_i_u_0->data[i_u_0], r_i_u_1->data[i_u_1], r_i_u_2->data[i_u_2]
            );

        // for (int j = 0; j < vcd->signal_count; j++) {
        //     vcd_signal_t *signal = &vcd->signals[j];
        //     if (signal->valid[i])
        //         printf("%s=0x%016lx ", signal->name, signal->data[i]);
        //     else
        //         printf("%s=0xXXXXXXXXXXXXXXXX ", signal->name);
        // }
        puts("");
    }
    

    vcd_close(vcd);
    
    return EXIT_SUCCESS;
}
