--------------------------------------------------------------------------------
--! @file
--! @brief Leading Zero Detection
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package lzd_pkg is

  procedure lzdp_2 (
    signal l_din : in std_logic_vector(1 downto 0);
    variable l_p  : out std_logic_vector(0 downto 0);
    variable l_v  : out std_logic);
 
  procedure lzdp_4 (
    signal l_din : in std_logic_vector(3 downto 0);
    variable l_p : out std_logic_vector(1 downto 0);
    variable l_v : out std_logic);
    
  procedure lzdp_8 (
    signal l_din : in std_logic_vector(7 downto 0);
    variable l_p : out std_logic_vector(2 downto 0);
    variable l_v : out std_logic);
    
  procedure lzdp_16 (
    signal l_din : in std_logic_vector(15 downto 0);
    variable l_p : out std_logic_vector(3 downto 0);
    variable l_v : out std_logic);
    
  procedure lzdp_32 (
    signal l_din : in std_logic_vector(31 downto 0);
    variable l_p : out std_logic_vector(4 downto 0);
    variable l_v : out std_logic);
    
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
    variable l_v  : out std_logic) is
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



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg.all;

entity lzd_32 is
    port (  clk : in std_logic;
            rstn : in std_logic;
            en : in std_logic;
            din : in std_logic_vector(31 downto 0);
            p : out unsigned(4 downto 0);
            v : out std_logic
            );
        
end lzd_32;

architecture beh of lzd_32 is
    signal r_p : std_logic_vector(4 downto 0);
    signal r_v : std_logic;
begin

    process (rstn, clk)
        variable v_p : std_logic_vector(4 downto 0);
        variable v_v : std_logic;
    begin
        if rstn = '0' then
            r_p <= (others => '0');
            r_v <= '0';
        elsif rising_edge(clk) then
            if en = '1' then
                lzdp_32(din, v_p, v_v);
                r_v <= v_v;
                
                if v_v = '1' then
                    r_p <= v_p;
                else
                    r_p <= std_logic_vector(to_unsigned(32, 5)); -- Ugh ... oh well, doesn't ever happen
                end if;
            end if;
        end if;
    end process run;
    
    p <= unsigned(r_p);
    v <= r_v;

end beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg.all;

entity lzd_48 is
    Port ( clk : in STD_LOGIC;
           rstn : in STD_LOGIC;
           en : in STD_LOGIC;
           din : in STD_LOGIC_VECTOR (47 downto 0);
           p : out unsigned (5 downto 0));
end lzd_48;

architecture beh of lzd_48 is
    signal r_p : std_logic_vector(5 downto 0);
begin
    process (rstn, clk)
        variable v_p : std_logic_vector(5 downto 0);
        variable v_v : std_logic;
    begin
        if rstn = '0' then
            r_p <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                lzdp_48(din, v_p, v_v);
                if v_v = '1' then
                    r_p <= v_p;
                else
                    r_p <= std_logic_vector(to_unsigned(48, 6));
                end if;
            end if;
        end if;
    end process run;
    
    p <= unsigned(r_p);
end beh;
