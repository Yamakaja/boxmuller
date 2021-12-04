--------------------------------------------------------------------------------
--! @file
--! @brief Leading Zero Detection
--! @author David Winter
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

--! This package defines the lzd helper procedures that can be used
--! to synthesize the final lzd logic. All of these procedures are of
--! a purely combinatorial nature.
package lzd_pkg is
  
    --! Two-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_2 (
        signal l_din : in std_logic_vector(1 downto 0);
        variable l_p  : out std_logic_vector(0 downto 0);
        variable l_v  : out std_logic);
 
    --! 4-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_4 (
        signal l_din : in std_logic_vector(3 downto 0);
        variable l_p : out std_logic_vector(1 downto 0);
        variable l_v : out std_logic);
    
    --! 8-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_8 (
        signal l_din : in std_logic_vector(7 downto 0);
        variable l_p : out std_logic_vector(2 downto 0);
        variable l_v : out std_logic);
    
    --! 16-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_16 (
        signal l_din : in std_logic_vector(15 downto 0);
        variable l_p : out std_logic_vector(3 downto 0);
        variable l_v : out std_logic);
    
    --! 32-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_32 (
        signal l_din : in std_logic_vector(31 downto 0);
        variable l_p : out std_logic_vector(4 downto 0);
        variable l_v : out std_logic);
    
    --! 48-bit leading zero detector construction helper
    --! \param l_din    Input Data
    --! \param l_p      Leading zero count
    --! \param l_v      Leading zero count valid bit
    procedure lzdp_48 (
        signal l_din : in std_logic_vector(47 downto 0);
        variable l_p : out std_logic_vector(5 downto 0);
        variable l_v : out std_logic);
    
end package lzd_pkg;

package body lzd_pkg is

  procedure lzdp_helper(
    l_v : out std_logic;
    l_p : out std_logic_vector;
    r_v : in std_logic_vector(1 downto 0);
    r_p_a : in std_logic_vector;
    r_p_b : in std_logic_vector;
    constant r_p_size : integer
    ) is
    variable     r_p_tmp : std_logic_vector(r_p_size - 1 downto 0);
  begin
    l_v := r_v(0) or r_v(1);
    
    if r_v(1) = '1' then
        r_p_tmp := r_p_b;
    else
        r_p_tmp := r_p_a;
    end if;
    
    l_p := (not r_v(1)) & r_p_tmp;        
  end lzdp_helper;
  
  procedure lzdp_2 (
    signal l_din : in std_logic_vector(1 downto 0);
    variable l_p  : out std_logic_vector(0 downto 0);
    variable l_v  : out std_logic
  ) is
  begin
    l_v := l_din(0) or l_din(1);
    l_p(0) := l_din(0) and not l_din(1);
  end lzdp_2;
  
  procedure lzdp_4 (
    signal l_din : in std_logic_vector(3 downto 0);
    variable l_p : out std_logic_vector(1 downto 0);
    variable l_v : out std_logic) is
    
    variable r_p_a : std_logic_vector(0 downto 0);
    variable r_p_b : std_logic_vector(0 downto 0);
    variable r_v : std_logic_vector(1 downto 0);
  begin
    lzdp_2(l_din(3 downto 2), r_p_b, r_v(1));
    lzdp_2(l_din(1 downto 0), r_p_a, r_v(0));
    
    lzdp_helper(l_v,l_p, r_v, r_p_a, r_p_b, 1);
  end lzdp_4;
  
  procedure lzdp_8 (
    signal l_din : in std_logic_vector(7 downto 0);
    variable l_p : out std_logic_vector(2 downto 0);
    variable l_v : out std_logic) is
    
    variable r_p_a : std_logic_vector(1 downto 0);
    variable r_p_b : std_logic_vector(1 downto 0);
    variable r_v : std_logic_vector(1 downto 0);
  begin
    lzdp_4(l_din(7 downto 4), r_p_b, r_v(1));
    lzdp_4(l_din(3 downto 0), r_p_a, r_v(0));
    
    lzdp_helper(l_v, l_p, r_v, r_p_a, r_p_b, 2);
  end lzdp_8;
  
  procedure lzdp_16 (
    signal l_din : in std_logic_vector(15 downto 0);
    variable l_p : out std_logic_vector(3 downto 0);
    variable l_v : out std_logic) is
    
    variable r_p_a : std_logic_vector(2 downto 0);
    variable r_p_b : std_logic_vector(2 downto 0);
    variable r_v : std_logic_vector(1 downto 0);
  begin
    lzdp_8(l_din(15 downto 8), r_p_b, r_v(1));
    lzdp_8(l_din(7 downto 0), r_p_a, r_v(0));
    
    lzdp_helper(l_v, l_p, r_v, r_p_a, r_p_b, 3);
  end lzdp_16;
  
  procedure lzdp_32 (
    signal l_din : in std_logic_vector(31 downto 0);
    variable l_p : out std_logic_vector(4 downto 0);
    variable l_v : out std_logic) is
    
    variable r_p_a : std_logic_vector(3 downto 0);
    variable r_p_b : std_logic_vector(3 downto 0);
    variable r_v : std_logic_vector(1 downto 0);
  begin
    lzdp_16(l_din(31 downto 16), r_p_b, r_v(1));
    lzdp_16(l_din(15 downto 0), r_p_a, r_v(0));
    
    lzdp_helper(l_v, l_p, r_v, r_p_a, r_p_b, 4);
  end lzdp_32;
    
  procedure lzdp_48 (
    signal l_din : in std_logic_vector(47 downto 0);
    variable l_p : out std_logic_vector(5 downto 0);
    variable l_v : out std_logic) is
    
    variable r_p_a : std_logic_vector(4 downto 0);
    variable r_p_b : std_logic_vector(4 downto 0);
    variable r_v : std_logic_vector(1 downto 0);
  begin
    lzdp_32(l_din(47 downto 16), r_p_b, r_v(1));
    r_p_a(4) := '0';
    lzdp_16(l_din(15 downto 0), r_p_a(3 downto 0), r_v(0));
    
    lzdp_helper(l_v, l_p, r_v, r_p_a, r_p_b, 5);
  end lzdp_48;
  
end lzd_pkg;



--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! LZD helper procedures
use work.lzd_pkg.all;

--! Implements a 32-bit leading zero detector from the lzd-procedures defined in lzd_pkg.
--!
--! Throughput: 1 sample/cycle.
--! Delay:      1 cycle
entity lzd_32 is
    port (  clk : in std_logic;                         --! Input clock
            rstn : in std_logic;                        --! Inverted reset
            en : in std_logic;                          --! Clock enable
            din : in std_logic_vector(31 downto 0);     --! Data input
            p : out unsigned(4 downto 0);               --! Leading zero count output
            v : out std_logic                           --! Leading zero count valid bit output
            );
        
end lzd_32;

architecture beh of lzd_32 is
    signal r_p : std_logic_vector(4 downto 0);
    signal r_v : std_logic;
begin

    process (clk)
        variable v_p : std_logic_vector(4 downto 0);
        variable v_v : std_logic;
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                r_p <= (others => '0');
                r_v <= '0';
            elsif en = '1' then
                lzdp_32(din, v_p, v_v);
                r_v <= v_v;
                
                if v_v = '1' then
                    r_p <= v_p;
                else
                    r_p <= std_logic_vector(to_unsigned(32, 5)); -- Ugh ... oh well, doesn't ever happen
                end if;
            end if;
        end if;
    end process;
    
    p <= unsigned(r_p);
    v <= r_v;

end beh;

--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! LZD helper procedures
use work.lzd_pkg.all;

--! Implements a 48-bit leading zero detector from the lzd-procedures defined in lzd_pkg.
--!
--! Throughput: 1 sample/cycle.
--! Delay:      1 cycle
entity lzd_48 is
    Port ( clk : in STD_LOGIC;                      --! Input clock
           rstn : in STD_LOGIC;                     --! Inverted reset
           en : in STD_LOGIC;                       --! Clock enable
           din : in STD_LOGIC_VECTOR (47 downto 0); --! Data input
           p : out unsigned (5 downto 0));          --! Leading zero count output, always valid; = 48 for din = 0.
end lzd_48;

architecture beh of lzd_48 is
    signal r_p : std_logic_vector(5 downto 0);
begin
    process (clk)
        variable v_p : std_logic_vector(5 downto 0);
        variable v_v : std_logic;
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                r_p <= (others => '0');
            elsif en = '1' then
                lzdp_48(din, v_p, v_v);
                if v_v = '1' then
                    r_p <= v_p;
                else
                    r_p <= std_logic_vector(to_unsigned(48, 6));
                end if;
            end if;
        end if;
    end process;
    
    p <= unsigned(r_p);
end beh;
