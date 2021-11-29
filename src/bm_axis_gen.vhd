library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.and_reduce;
use ieee.numeric_std.all;

entity bm_axis_gen is
    generic (
        COUNTER_WIDTH   : integer := 6
    );
    port (
        clk             : in  std_logic;                        --! Clock input
        rstn            : in  std_logic;                        --! Asynchronous inverted reset
        en              : in  std_logic;                        --! Enable signal, not a traditional clock enable!
        factor_in       : in  unsigned(15 downto 0);            --! The factor input, may change arbitrarily
        factor_out      : out unsigned(15 downto 0);            --! Factor output, stable as necessary for SD-FEC
        offset_in       : in  signed(7 downto 0);               --! Offset input from regmap
        offset_out      : out signed(7 downto 0);               --! Offset output, stable as necessary for SD-FEC
        din             : in  std_logic_vector(127 downto 0);   --! Input data from output remappers
        din_beats       : in  unsigned(15 downto 0);            --! How many beats the AXIS transaction should have
        m_axis_tready   : in  std_logic;                        --! AXIS Stream
        m_axis_tvalid   : out std_logic;                        --! AXIS Stream
        m_axis_tdata    : out std_logic_vector(127 downto 0);   --! AXIS Stream
        m_axis_tlast    : out std_logic;                        --! AXIS Stream
        sub_en          : out std_logic                         --! The clock enable for output remapper, boxmuller and xoroshiro
    );
end bm_axis_gen;

architecture beh of bm_axis_gen is
    
    type t_state is (IDLE, INITIALIZING, RUNNING, ENDING);
    signal r_state          : t_state;

    signal r_valid_counter  : unsigned(COUNTER_WIDTH - 1 downto 0);
    signal r_axis_tdata     : std_logic_vector(din'range);
    signal r_axis_tvalid    : std_logic;
    signal r_axis_tlast     : std_logic;
    signal r_din_beats      : unsigned(15 downto 0);
    signal r_beat_counter   : unsigned(15 downto 0);
    signal r_factor         : unsigned(15 downto 0);
    signal r_offset         : signed(7 downto 0);
    
    signal w_input_valid    : std_logic;
begin

    -- The idea behind this core:
    -- The "bm_axis_gen" module is reponsible for controlling the boxmuller,
    -- xoroshiro and remapping cores, and converting their outputs into something
    -- that can be fed into the SD-FEC cores. This results in a couple constraints
    -- which have to be kept in mind:
    --
    -- * The boxmuller cores, and by extension the output_remapper, produce junk
    --   while registers are still uninitialized and the pipeline is being flushed,
    --   consequently the it is the responsibility of this core to make sure those
    --   invalid samples never make it to the output.
    -- * The SD-FEC always works in blocks of din_beats input beats, and stopping
    --   the output stream with some data still in on the fly could result in bad
    --   data making it into the next test. Thus this block doesn't treat `en` as
    --   a traditional clock enable, but rather as a suggestion as to when no new
    --   transactions should be started.
    -- * Additionally, over the course of one of such blocks the factor and offset
    --   values must be kept stable!
    --
    -- These conditions make a simple state machine the tool of choice for this scenario:
    -- We introduce four states:
    --
    -- * IDLE: In this state the module is waiting for the enable signal to go high,
    --         and thus indicate that the configuration inputs have been initialized.
    --         Once en has gone high, the state transitions into INITIALIZING.
    -- * INITIALIZING: In this state the output valid is still held and the random
    --         number generator cores are given some cycles to flush the pipelines.
    --         The state will automatically transition to RUNNING after 64 cycles.
    -- * RUNNING: Here the output is finally enabled and samples are allowed to
    --         flow. Internally, the current position inside of a block is kept
    --         track of using r_beat_counter, which wraps around when reaching
    --         din_beats. Once en goes low the state is transitioned to ENDING.
    -- * ENDING: Here the output is still kept valid and samples are still
    --         requested from the RNGs, but only the current transaction is
    --         allowed to complete before going back to IDLE.

    -- Output driving registers
    m_axis_tdata    <= r_axis_tdata;
    m_axis_tvalid   <= r_axis_tvalid;
    m_axis_tlast    <= r_axis_tlast;

    factor_out      <= r_factor;
    offset_out      <= r_offset;

    sub_en <= '1' when r_state /= IDLE or en = '1' else '0';

    state_machine : process (clk, rstn)
    begin
        if rstn = '0' then
            r_state <= IDLE;
            r_valid_counter <= (others => '0');
            r_axis_tdata <= (others => '0');
            r_axis_tvalid <= '0';
            r_axis_tlast <= '0';
            r_beat_counter <= (others => '0');
            r_din_beats <= (others => '0');
            r_factor <= (others => '0');
            r_offset <= (others => '0');
        elsif rising_edge(clk) then
            case r_state is
                when IDLE =>
                    if en = '1' then
                        r_state <= INITIALIZING;

                        r_factor <= factor_in;
                        r_offset <= offset_in;
                        r_valid_counter <= (others => '0');
                        r_din_beats <= din_beats;
                    end if;

                when INITIALIZING =>
                    r_valid_counter <= r_valid_counter + 1;

                    if en = '0' then
                        r_state <= IDLE;
                    elsif and_reduce(std_logic_vector(r_valid_counter)) = '1' then
                        r_state <= RUNNING;

                        r_beat_counter <= (others => '0');
                        r_axis_tvalid <= '1';
                        r_axis_tdata <= din;
                    end if;

                when RUNNING =>
                    r_axis_tvalid <= '1';

                    if r_axis_tvalid = '1' and m_axis_tready = '1' then
                        -- Enable tlast on last beat
                        if r_beat_counter + 2 = r_din_beats then
                            r_axis_tlast <= '1';
                        else
                            r_axis_tlast <= '0';
                        end if;

                        r_axis_tdata <= din;

                        if r_axis_tlast = '1' then
                            -- Going low for one cycle
                            r_beat_counter <= (others => '0');
                            r_axis_tlast <= '0';
                            r_axis_tvalid <= '0';
                        else
                            r_beat_counter <= r_beat_counter + 1;
                        end if;
                    end if;

                    if en = '0' then
                        r_state <= ENDING;
                    end if;

                when ENDING => 
                    r_axis_tvalid <= '1';

                    if r_axis_tvalid = '1' and m_axis_tready = '1' then
                        if r_beat_counter + 2 = r_din_beats then
                            r_axis_tlast <= '1';
                        else
                            r_axis_tlast <= '0';
                        end if;
                        r_axis_tdata <= din;

                        if r_axis_tlast = '1' then
                            r_state <= IDLE;

                            r_axis_tvalid <= '0';
                            r_axis_tlast <= '0';
                        else
                            r_beat_counter <= r_beat_counter + 1;
                        end if;
                    end if;
                when others =>
                    r_state <= IDLE;

            end case;
        end if;
    end process state_machine;

end beh;
