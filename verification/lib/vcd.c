#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <stdbool.h>

#include "vcd.h"

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

vcd_t *vcd_open(char *file) {

    FILE *input_file = fopen(file, "r");
    if (!input_file)
        return NULL;

    vcd_t *vcd = malloc(sizeof(vcd_t));
    
    if (!vcd)
        return NULL;

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

    vcd->time = 0;
    return vcd;
}

void vcd_close(vcd_t *vcd) {
    fclose(vcd->source);

    free(vcd->version);
    free(vcd->timescale);
    free(vcd->date);
    free(vcd->comment);
    free(vcd->line_buffer);

    for (int i = 0; i < vcd->signal_count; i++)
        free(vcd->signals[i].name);

    free(vcd->signals);

    free(vcd);
}

ssize_t vcd_next_line(vcd_t *vcd) {
    vcd->line_idx++;
    return getline(&vcd->line_buffer, &vcd->line_n, vcd->source);
}

void vcd_add_signal(vcd_t *vcd, char *line) {
    vcd_signal_t *signal = malloc(sizeof(vcd_signal_t));
    signal->name = malloc(strlen(line));
    char symbol[2];
    sscanf(line, "var wire %d %s %s $end", &signal->width, symbol, signal->name);
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

    // memcpy(&signal_block[0], vcd->signals, sizeof(vcd_signal_t));

    // for (int i = 1; i < vcd->signal_count; i++)
    //     memcpy(&signal_block[i], signal_block[i-1].next, sizeof(vcd_signal_t));

    vcd_signal_t *next = vcd->signals;
    while (next != NULL) {
        
        size_t idx = (size_t)(next->symbol - vcd->lowest_symbol);
        memcpy(&signal_block[idx], next, sizeof(vcd_signal_t));

        vcd_signal_t *tmp = next;
        next = next->next;
        free(tmp);
    }

    vcd->signals = signal_block;
}

void vcd_parse_body_line(vcd_t *vcd) {
    char data[64];
    size_t len;
    char *line;
    char symbol;
    switch (vcd->line_buffer[0]) {
        case '$':
            // Ignore
            break;
        case '#':
            sscanf(vcd->line_buffer + 1, "%lu", &vcd->time);
            return;
        case 'b':
            line = vcd->line_buffer;
 
            sscanf(line, "b%s %c", data, &symbol);
            len = strlen(data);

            vcd_signal_t *signal = &vcd->signals[(size_t)(symbol - vcd->lowest_symbol)];
            signal->valid = true;
            signal->data = 0UL;

            for (size_t i = 0; i < len; i++) {                
                switch (data[i]) {
                    case '0':
                        signal->data = (signal->data << 1) & (~0x1UL);;
                        break;
                    case '1':
                        signal->data = (signal->data << 1) | 0x1UL;
                        break;
                    default:
                        signal->valid = false;
                        break;
                }
            }

    }
}

void vcd_next(vcd_t *vcd) {
    do {
        vcd_parse_body_line(vcd);
        vcd_next_line(vcd);
    } while (!feof(vcd->source) && vcd->line_buffer[0] != '#');
}

bool vcd_has_next(vcd_t *vcd) {
    return !feof(vcd->source);
}
