#ifndef HEADER_VCD
#define HEADER_VCD

typedef enum vcd_state_t {
    HEADER,
    DATE,
    VERSION,
    COMMENT,
    TIMESCALE,
    DUMPVARS,
    BODY
} vcd_state_t;

typedef struct vcd_signal_t {
    char *name;
    char symbol;
    int width;
    void *next;
    bool *valid;
    uint64_t *data;
    bool processed;
} vcd_signal_t;

typedef struct vcd_t {
    vcd_state_t state;
    vcd_signal_t *signals;
    int signal_count;
    char lowest_symbol;
    char highest_symbol;
    char *version;
    char *timescale;
    char *date;
    char *comment;

    ssize_t history_length;
    ssize_t history_length_log;
    ssize_t history_length_mask;
    ssize_t timeslot_idx;

    FILE *source;
    char *line_buffer;
    size_t line_n;
    size_t line_idx;

    uint64_t time;
} vcd_t;

vcd_t *vcd_open(char *file, size_t history_length_log);

void vcd_close(vcd_t *vcd);

void vcd_parse_header(vcd_t *vcd);

void vcd_next(vcd_t *vcd);

void vcd_skip(vcd_t *vcd, size_t n);

size_t vcd_get_data_idx(vcd_t *vcd, ssize_t i);

bool vcd_has_next(vcd_t *vcd);

vcd_signal_t *vcd_get_signal_by_name(vcd_t *vcd, char *name);

#endif
