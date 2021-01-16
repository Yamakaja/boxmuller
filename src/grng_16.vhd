--------------------------------------------------------------------------------
--! @file
--! @brief 128-bit wide GRNG (16 values @ 6 bit + 2 bits of padding (signed))
--! @author David Winter
--------------------------------------------------------------------------------
--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! Import pre-calculated xoroshiro seeds
use work.xoro_seeds.all;

--! 128-bit wide GRNG (16 values @ 6 bit + 2 bits of padding (signed))
entity grng_16 is
    generic (
        xoro_seed_base : integer := 0                                   --! The xoroshiro seed base, to avoid overlaps
        );
    port (
        clk     : in std_logic;                                         --! Clock in
        rstn    : in std_logic;                                         --! Inverted Reset
        en      : in std_logic;                                         --! Enable
        
        s_axis_tdata    : out std_logic_vector(8 * 16 - 1 downto 0);    --! AXI Stream Data Out
        s_axis_tready   : in std_logic;                                 --! AXI Stream Ready In
        s_axis_tvalid   : out std_logic;                                --! AXI Stream Valid Out
        
        sb_din  : in std_logic;                                         --! Shiftbus Data In
        sb_en   : in std_logic                                          --! Shiftbus Enable
    );
end grng_16;

architecture beh of grng_16 is
    component boxmueller is
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
    
    component sb_des is
        generic (
            DEPTH : integer := 24
        );
        port (
            clk     : in std_logic;
            rstn    : in std_logic;
            sb_data : in std_logic;
            sb_en   : in std_logic;
            dout    : out std_logic_vector(DEPTH - 1 downto 0);
            updated : out std_logic
        );
    end component;
    
    component bm_axis_gen is
        generic (
            COUNTER_WIDTH : integer := 6
        );
        port (
            clk             : in std_logic;
            rstn            : in std_logic;
            en              : in std_logic;
            updated         : in std_logic;
            din             : in std_logic_vector(127 downto 0);
            s_axis_tready   : in std_logic;
            s_axis_tvalid   : out std_logic;
            s_axis_tdata    : out std_logic_vector(127 downto 0);
            sub_en          : out std_logic
        );
    end component bm_axis_gen;
    
    constant BM_IN_WIDTH    : integer :=    96;
    constant BM_COUNT       : integer :=    8;
    constant XORO_OUT_WIDTH : integer :=    64;
    constant XORO_COUNT     : integer :=    BM_IN_WIDTH * BM_COUNT / XORO_OUT_WIDTH;
    
    constant SB_FAC_WIDTH   : integer := 16;
    constant SB_OFF_WIDTH   : integer := 8;
    
    signal w_xoro_data      : std_logic_vector(XORO_COUNT * XORO_OUT_WIDTH - 1 downto 0);
    
    type w_bm_out_t is array(2 * BM_COUNT - 1 downto 0) of signed(15 downto 0);
    signal w_bm_out         : w_bm_out_t;
    
    signal w_sb_data : std_logic_vector(23 downto 0);
    signal w_updated : std_logic;
    
    signal w_sub_en : std_logic;
    
    signal w_remapped : signed(2 * BM_COUNT * 8 - 1 downto 0);
    
begin

    axis_gen : bm_axis_gen
        generic map (
            COUNTER_WIDTH   => 6
        )
        port map (
            clk             => clk,
            rstn            => rstn,
            en              => en,
            updated         => w_updated,
            din             => std_logic_vector(w_remapped),
            s_axis_tready   => s_axis_tready,
            s_axis_tvalid   => s_axis_tvalid,
            s_axis_tdata    => s_axis_tdata,
            sub_en          => w_sub_en
        );

    sb : sb_des
        generic map (
            DEPTH => SB_FAC_WIDTH + SB_OFF_WIDTH
        )
        port map (
            clk     => clk,
            rstn    => rstn,
            sb_data => sb_din,
            sb_en   => sb_en,
            dout    => w_sb_data,
            updated => w_updated
        );
    
    gen_remapper:
    for i in 0 to 2*BM_COUNT-1 generate
        out_remap : output_remapper
            port map (
                clk     => clk,
                rstn    => rstn,
                en      => w_sub_en,
                din     => w_bm_out(i),
                factor  => signed(w_sb_data(SB_FAC_WIDTH + SB_OFF_WIDTH - 1 downto SB_OFF_WIDTH)),
                offset  => signed(w_sb_data(SB_OFF_WIDTH - 1 downto 0)),
                dout    => w_remapped((i+1)*8-1 downto i*8)
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
                rstn   => rstn,
                enable => w_sub_en,
                dout   => w_xoro_data((i+1)*XORO_OUT_WIDTH - 1 downto i*XORO_OUT_WIDTH)
            );
    end generate gen_rand;
    
    gen_bm:
    for i in 0 to BM_COUNT-1 generate
        bm : boxmueller
            port map (
                clk  => clk,
                rstn => rstn,
                en   => w_sub_en,
                u    => w_xoro_data((i+1)*BM_IN_WIDTH - 1 downto i * BM_IN_WIDTH),
                x_0  => w_bm_out(2*i + 0),
                x_1  => w_bm_out(2*i + 1)
            );
    end generate gen_bm;

end beh;
