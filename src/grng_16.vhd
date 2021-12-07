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
        data        : out std_logic_vector(8*16 - 1 downto 0);          --! Remapped data output
        
        factor      : in std_logic_vector(15 downto 0);                 --! sigma of normal distribution
        offset      : in std_logic_vector( 7 downto 0)                  --! mu    of normal distribution
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

    constant BM_IN_WIDTH    : integer :=    96;
    constant BM_COUNT       : integer :=    8;
    constant XORO_OUT_WIDTH : integer :=    64;
    constant XORO_COUNT     : integer :=    BM_IN_WIDTH * BM_COUNT / XORO_OUT_WIDTH;
    
    signal w_xoro_data      : std_logic_vector(XORO_COUNT * XORO_OUT_WIDTH - 1 downto 0);
    
    type w_bm_out_t is array(2 * BM_COUNT - 1 downto 0) of signed(15 downto 0);
    signal w_bm_out         : w_bm_out_t;
    
    signal w_remapped       : signed(2 * BM_COUNT * 8 - 1 downto 0);
begin

    data <= std_logic_vector(w_remapped);

    gen_remapper:
    for i in 0 to 2*BM_COUNT-1 generate
        out_remapper : output_remapper
            port map (
                clk     => clk,
                rstn    => resetn,
                en      => en,
                din     => w_bm_out(i),
                factor  => signed(factor),
                offset  => signed(offset),
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
                rstn   => resetn,
                enable => en,
                dout   => w_xoro_data((i+1)*XORO_OUT_WIDTH - 1 downto i*XORO_OUT_WIDTH)
            );
    end generate gen_rand;
    
    gen_bm:
    for i in 0 to BM_COUNT-1 generate
        bm : boxmuller
            port map (
                clk  => clk,
                rstn => resetn,
                en   => en,
                u    => w_xoro_data((i+1)*BM_IN_WIDTH - 1 downto i * BM_IN_WIDTH),
                x_0  => w_bm_out(2*i + 0),
                x_1  => w_bm_out(2*i + 1)
            );
    end generate gen_bm;

end beh;
