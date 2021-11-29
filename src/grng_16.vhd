--------------------------------------------------------------------------------
--! @file
--! @brief 128-bit wide GRNG (16 values @ 6 bit + 2 bits of padding (signed))
--! @author David Winter
--------------------------------------------------------------------------------
--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! Import pre-calculated xoroshiro seeds
use work.xoro_seeds.all;

--! 128-bit wide GRNG (16 values @ 6 bit + 2 bits of padding (signed))
entity grng_16 is
    generic (
        xoro_seed_base : integer := 0                                   --! The seed base is an index into an array of seeds that will be used to initialize the uniform random number generators of this core. To avoid seed duplication, increment this value by one for each instance of this core in your design!
        );
    port (
        clk         : in std_logic;                                     --! Clock in
        resetn      : in std_logic;                                     --! Inverted Reset
        en          : in std_logic;                                     --! Enable
        
        m_axis_tdata    : out std_logic_vector(8 * 16 - 1 downto 0);    --! AXI Stream Data Out
        m_axis_tready   : in std_logic;                                 --! AXI Stream Ready In
        m_axis_tvalid   : out std_logic;                                --! AXI Stream Valid Out
        m_axis_tlast    : out std_logic;                                --! AXI Stream Last Out
        
        factor_in   : in std_logic_vector(15 downto 0);                 --! sigma of normal distribution
        offset_in   : in std_logic_vector( 7 downto 0);                 --! mu    of normal distribution
        din_beats   : in std_logic_vector(15 downto 0)
        
    );
end grng_16;

architecture beh of grng_16 is
    component boxmuller is
        port (
            clk  : in std_logic;
            rstn : in std_logic;
            en   : in std_logic;
            u    : in std_logic_vector(95 downto 0);
            x_0  : out signed(15 downto 0);
            x_1  : out signed(15 downto 0)
        );
    end component;

    component xoroshiro128plus is
    generic (
        seed_1 : unsigned(63 downto 0);
        seed_0 : unsigned(63 downto 0)
        );
    port (
        clk    : in  std_logic;
        rstn   : in  std_logic;
        enable : in  std_logic;
        dout   : out std_logic_vector(63 downto 0)
    );
    end component;
    
    component output_remapper is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            en   : in std_logic;
            din    : in signed (15 downto 0); -- 5,11
            factor : in signed (15 downto 0); -- 8,8
            offset : in signed (7 downto 0);  -- 6,2
            dout   : out signed(7 downto 0)
        );
    end component;

    component output_remapper_fixpt is
        port (
             clk            : in std_logic;
            rstn            : in std_logic;
            en              : in std_logic;
            x_in            : in signed(15 downto 0);  -- sfix16_En11
            factor          : in unsigned(15 downto 0);  -- ufix16_En8
            offset          : in signed(7 downto 0);  -- sfix8_En2
            ce_out          : out std_logic;
            y_out           : out signed(7 downto 0)  -- sfix8_En2
            );
    end component output_remapper_fixpt;
    
    component bm_axis_gen is
        generic (
            COUNTER_WIDTH : integer := 6
        );
        port (
            clk             : in std_logic;
            rstn            : in std_logic;
            en              : in std_logic;
            factor_in       : in  unsigned(15 downto 0);
            factor_out      : out unsigned(15 downto 0);
            offset_in       : in  signed(7 downto 0);
            offset_out      : out signed(7 downto 0);
            din             : in  std_logic_vector(127 downto 0);
            din_beats       : in  unsigned(15 downto 0);
            m_axis_tready   : in std_logic;
            m_axis_tvalid   : out std_logic;
            m_axis_tdata    : out std_logic_vector(127 downto 0);
            m_axis_tlast    : out std_logic;
            sub_en          : out std_logic
        );
    end component bm_axis_gen;
    
    constant BM_IN_WIDTH    : integer :=    96;
    constant BM_COUNT       : integer :=    8;
    constant XORO_OUT_WIDTH : integer :=    64;
    constant XORO_COUNT     : integer :=    BM_IN_WIDTH * BM_COUNT / XORO_OUT_WIDTH;
    
    signal w_xoro_data      : std_logic_vector(XORO_COUNT * XORO_OUT_WIDTH - 1 downto 0);
    
    type w_bm_out_t is array(2 * BM_COUNT - 1 downto 0) of signed(15 downto 0);
    signal w_bm_out         : w_bm_out_t;
    
    signal r_updated        : std_logic;
    signal r_factor_d       : std_logic_vector(15 downto 0);
    signal r_offset_d       : std_logic_vector( 7 downto 0);
    signal w_sub_en         : std_logic;
    
    signal w_remapped       : signed(2 * BM_COUNT * 8 - 1 downto 0);

    signal factor           : unsigned(15 downto 0);
    signal offset           : signed(7 downto 0);
    
begin

    axis_gen : bm_axis_gen
        generic map (
            COUNTER_WIDTH   => 6
        )
        port map (
            clk             => clk,
            rstn            => resetn,
            en              => en,
            factor_in       => unsigned(factor_in),
            factor_out      => factor,
            offset_in       => signed(offset_in),
            offset_out      => offset,
            din             => std_logic_vector(w_remapped),
            din_beats       => unsigned(din_beats),
            m_axis_tready   => m_axis_tready,
            m_axis_tvalid   => m_axis_tvalid,
            m_axis_tdata    => m_axis_tdata,
            m_axis_tlast    => m_axis_tlast,
            sub_en          => w_sub_en
        );

    gen_remapper:
    for i in 0 to 2*BM_COUNT-1 generate

        out_remap_fixpt : output_remapper_fixpt
            port map (
                clk     => clk,
                rstn    => resetn,
                en      => w_sub_en,
                x_in    => w_bm_out(i),
                factor  => unsigned(factor),
                offset  => signed(offset),
                y_out   => w_remapped((i+1)*8-1 downto i*8)
            );

    end generate;

    gen_rand:
    for i in 0 to XORO_COUNT-1 generate
        rand : xoroshiro128plus
            generic map (
                seed_1 => xoro_seeds(xoro_seed_base*XORO_COUNT+i)(1),
                seed_0 => xoro_seeds(xoro_seed_base*XORO_COUNT+i)(0)
                )
            port map (
                clk    => clk,
                rstn   => resetn,
                enable => w_sub_en,
                dout   => w_xoro_data((i+1)*XORO_OUT_WIDTH - 1 downto i*XORO_OUT_WIDTH)
            );
    end generate gen_rand;
    
    gen_bm:
    for i in 0 to BM_COUNT-1 generate
        bm : boxmuller
            port map (
                clk  => clk,
                rstn => resetn,
                en   => w_sub_en,
                u    => w_xoro_data((i+1)*BM_IN_WIDTH - 1 downto i * BM_IN_WIDTH),
                x_0  => w_bm_out(2*i + 0),
                x_1  => w_bm_out(2*i + 1)
            );
    end generate gen_bm;

end beh;
