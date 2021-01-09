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
    bool valid;
    uint64_t data;
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

    FILE *source;
    char *line_buffer;
    size_t line_n;
    size_t line_idx;

    uint64_t time;
} vcd_t;

vcd_t *vcd_open(char *file);

void vcd_close(vcd_t *vcd);

void vcd_parse_header(vcd_t *vcd);

void vcd_next(vcd_t *vcd);

bool vcd_has_next(vcd_t *vcd);

#endif
