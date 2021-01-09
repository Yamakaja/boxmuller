#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <stdbool.h>

#include "vcd.h"

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

vcd_t *vcd_open(char *file, size_t history_length_log) {

    FILE *input_file = fopen(file, "r");
    if (!input_file)
        return NULL;

    vcd_t *vcd = malloc(sizeof(vcd_t));
    
    if (!vcd)
        return NULL;

    vcd->history_length_log = history_length_log;
    vcd->history_length = 1UL << (history_length_log);
    vcd->history_length_mask = vcd->history_length - 1L;
    vcd->timeslot_idx = 0L;

    vcd->state = HEADER;
    vcd->signals = NULL;
    vcd->signal_count = 0;
    vcd->version = NULL;
    vcd->timescale = NULL;
    vcd->date = NULL;
    vcd->comment = NULL;
    vcd->lowest_symbol = 127;
    vcd->highest_symbol = 0;

    vcd->source = input_file;
    vcd->line_buffer = NULL;
    vcd->line_n = 0UL;
    vcd->line_idx = 0;

    vcd->time = 0UL;
    return vcd;
}

void vcd_close(vcd_t *vcd) {
    fclose(vcd->source);

    free(vcd->version);
    free(vcd->timescale);
    free(vcd->date);
    free(vcd->comment);
    free(vcd->line_buffer);

    for (int i = 0; i < vcd->signal_count; i++) {
        free(vcd->signals[i].name);
        free(vcd->signals[i].data);
        free(vcd->signals[i].valid);
    }

    free(vcd->signals);

    free(vcd);
}

ssize_t vcd_next_line(vcd_t *vcd) {
    vcd->line_idx++;
    return getline(&vcd->line_buffer, &vcd->line_n, vcd->source);
}

void vcd_add_signal(vcd_t *vcd, char *line) {
    vcd_signal_t *signal = malloc(sizeof(vcd_signal_t));
    signal->name  = malloc(sizeof(*line) * (strlen(line) + 1));
    signal->data  = malloc(sizeof(*signal->data) * vcd->history_length);
    signal->valid = malloc(sizeof(*signal->valid) * vcd->history_length);
    signal->processed = false;
    char symbol[2];
    sscanf(line, "var wire %d %s %s %*s $end", &signal->width, symbol, signal->name);

    if (signal->width > 64) {
        fprintf(stderr, "vcd_add_signal: Unsupported signal width > 64!\n");
        exit(EXIT_FAILURE);
    }

    vcd->lowest_symbol = MIN(vcd->lowest_symbol, symbol[0]);
    vcd->highest_symbol = MAX(vcd->highest_symbol, symbol[0]);
    signal->symbol = symbol[0];


    signal->next = vcd->signals;
    vcd->signals = signal;

    vcd->signal_count++;
}

void vcd_str_helper(vcd_t *vcd, size_t len, char **field, char *name) {
    if (vcd->line_buffer[0] == '$') {
        if (!strcmp(vcd->line_buffer, "$end")) {
            vcd->state = HEADER;
            return;
        }
        fprintf(stderr, "vcd_parse_header_line: unexpected command in %s state: %s", name, vcd->line_buffer); 
        return;
    }
    
    if (*field == NULL)
        *field = malloc(len+1);
    else
        *field = realloc(*field, len+1);
    
    strncpy(*field, vcd->line_buffer, len+1);
}

void vcd_parse_header_line(vcd_t *vcd) {
    size_t len = strlen(vcd->line_buffer);
    if (vcd->line_buffer[len - 1] == '\n')
        vcd->line_buffer[len - 1] = '\0';

    switch (vcd->state) {
        case BODY:
            fprintf(stderr, "vcd_parse_header_line: called when vcd->state == BODY!\n");
            exit(EXIT_FAILURE);
        case HEADER:
            if (len == 0)
                return;

            if (vcd->line_buffer[0] == '$') {
                char *command = vcd->line_buffer + 1;

                if (!strncmp(command, "date", len)) {
                    vcd->state = DATE;
                    return;
                } else if (!strncmp(command, "version", len)) {
                    vcd->state = VERSION;
                    return;
                } else if (!strncmp(command, "comment", len)) {
                    vcd->state = COMMENT;
                    return;
                } else if (!strncmp(command, "timescale", len)) {
                    vcd->state = TIMESCALE;
                    return;
                } else if (!strncmp(command, "scope", MIN(len, 5)) || !strncmp(command, "upscope", MIN(len, 7))) {
                    // Ignored
                    return;
                } else if (!strncmp(command, "enddefinitions", MIN(len, 14))) {
                    vcd->state = BODY;
                    return;
                } else if (!strncmp(command, "var ", MIN(len, 4))) {
                    vcd_add_signal(vcd, command);
                    return;
                }

                fprintf(stderr, "vcd_parse_header_line: skipping unhandled command in line %lu: %s\n", vcd->line_idx, command);
                return;
            }


            fprintf(stderr, "vcd_parse_header_line: expected command in header!\n");
            exit(EXIT_FAILURE);
        case DATE:
            vcd_str_helper(vcd, len, &vcd->date, "DATE");
            return;
        case VERSION:
            vcd_str_helper(vcd, len, &vcd->version, "VERSION");
            return;
        case COMMENT:
            vcd_str_helper(vcd, len, &vcd->comment, "COMMENT");
            return;
        case TIMESCALE:
            vcd_str_helper(vcd, len, &vcd->timescale, "TIMESCALE");
            return;
        case DUMPVARS:
            fprintf(stderr, "vcd_parse_header_line: Unexpected $dumpvars in header!\n");
            exit(EXIT_FAILURE);
            return;
    }
}

void vcd_parse_header(vcd_t *vcd) {
    do {
        ssize_t read = vcd_next_line(vcd);
        if (read == -1)
            break;

        vcd_parse_header_line(vcd);
    } while (!feof(vcd->source) && vcd->state != BODY);

    if (vcd_next_line(vcd) == -1)
        return;

    // Consolidate signals (aka. linked list to array)
    if (vcd->signals == NULL)
        return;

    size_t range = (size_t)(vcd->highest_symbol - vcd->lowest_symbol + 1);
    
    if (range < (size_t)(vcd->signal_count)) {
        fprintf(stderr, "vcd_parse_header: range < vcd->signal_count. aborting!\n");
        exit(EXIT_FAILURE);
    }

    vcd_signal_t *signal_block = malloc(sizeof(vcd_signal_t) * range);

    vcd_signal_t *next = vcd->signals;
    while (next != NULL) {
        
        size_t idx = (size_t)(next->symbol - vcd->lowest_symbol);
        memcpy(&signal_block[idx], next, sizeof(vcd_signal_t));
        signal_block[idx].next = NULL;

        vcd_signal_t *tmp = next;
        next = next->next;
        free(tmp);
    }

    vcd->signals = signal_block;
}

size_t vcd_get_data_idx(vcd_t *vcd, ssize_t i) {
    return vcd->history_length_mask & (vcd->history_length + i + vcd->timeslot_idx);
}

void vcd_parse_body_line(vcd_t *vcd) {
    char data[64];
    size_t len;
    char *line;
    char symbol;
    uint64_t new_time;
    uint64_t *data_ptr;
    ssize_t data_idx;

    switch (vcd->line_buffer[0]) {
        case '$':
            // Ignore
            break;
        case '#':
            sscanf(vcd->line_buffer + 1, "%lu", &new_time);
            if (new_time != vcd->time) {
                vcd->timeslot_idx++;
                vcd->time = new_time;
            }
            return;
        case 'b':
            line = vcd->line_buffer;
 
            sscanf(line, "b%s %c", data, &symbol);
            len = strlen(data);

            vcd_signal_t *signal = &vcd->signals[(size_t)(symbol - vcd->lowest_symbol)];

            data_idx = vcd_get_data_idx(vcd, 0);
            signal->valid[data_idx] = true;
            signal->processed = true;

            data_ptr = &signal->data[data_idx];
            *data_ptr = 0UL;

            for (size_t i = 0; i < len; i++) {                
                switch (data[i]) {
                    case '0':
                    case '1':
                        *data_ptr = (*data_ptr << 1) | (data[i] & 0x1);
                        break;
                    default:
                        signal->valid[data_idx] = false;
                        break;
                }
            }

    }
}

void vcd_next(vcd_t *vcd) {
    for (int i = 0; i < vcd->signal_count; i++)
        vcd->signals[i].processed = false;

    do {

        vcd_parse_body_line(vcd);
        vcd_next_line(vcd);
    } while (!feof(vcd->source) && vcd->line_buffer[0] != '#');

    ssize_t idx = vcd_get_data_idx(vcd, 0);
    ssize_t old_idx = vcd_get_data_idx(vcd, -1);
    for (int i = 0; i < vcd->signal_count; i++) {
        if (!vcd->signals[i].processed)
            vcd->signals[i].data[idx] = vcd->signals[i].data[old_idx];
    }
}

bool vcd_has_next(vcd_t *vcd) {
    return !feof(vcd->source);
}

vcd_signal_t *vcd_get_signal_by_name(vcd_t *vcd, char *name) {
    for (int i = 0; i < vcd->signal_count; i++)
        if (!strcmp(vcd->signals[i].name, name))
            return &vcd->signals[i];
    return NULL;
}

void vcd_skip(vcd_t *vcd, size_t n) {
    for (size_t i = 0; i < n; i++)
        vcd_next(vcd);
}
