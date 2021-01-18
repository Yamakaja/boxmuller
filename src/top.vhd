library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg.all;
use work.xoro_seeds.all;

entity top is
    port ( 
        clk     : in STD_LOGIC;
        rstn    : in STD_LOGIC;
        en      : in std_logic;
        
        sb_din  : in std_logic;
        sb_en   : in std_logic;
        
        s_axis_tready : in std_logic;
        s_axis_tdata : out std_logic;
        s_axis_tvalid : out std_logic
   );
end top;

architecture beh of top is

    component grng_16 is
        generic (
            xoro_seed_base : integer := 0
            );
        port (
            clk     : in std_logic;
            resetn  : in std_logic;
            en      : in std_logic;
            
            s_axis_tdata    : out std_logic_vector(8 * 16 - 1 downto 0);
            s_axis_tready   : in std_logic;
            s_axis_tvalid   : out std_logic;
            
            sb_din  : in std_logic;
            sb_en   : in std_logic
        );
    end component grng_16;
    
    function xor_reduct(slv : in std_logic_vector) return std_logic is
        variable res_v : std_logic := '1';  -- Null slv vector will also return '1'
    begin
        for i in slv'range loop
            res_v := res_v xor slv(i);
        end loop;
        return res_v;
    end function;
    
    signal r_axis_tdata : std_logic;
    signal w_axis_tdata : std_logic_vector(127 downto 0);

begin

    grng : grng_16
        generic map (
            xoro_seed_base => 0
            )
        port map (
            clk     => clk,
            resetn    => rstn,
            en      => en,
            
            s_axis_tdata    => w_axis_tdata,
            s_axis_tready   => s_axis_tready,
            s_axis_tvalid   => s_axis_tvalid,
            
            sb_din  => sb_din,
            sb_en   => sb_en
        );
    
    process (clk)
    begin
    
        if rising_edge(clk) and en = '1' then
            r_axis_tdata <= xor_reduct(w_axis_tdata);
        end if;
    end process;
    
    s_axis_tdata <= r_axis_tdata;
    
end beh;
