--------------------------------------------------------------------------------
--! @file
--! @brief XOROSHIRO128+ uniform random number generator
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xoroshiro128plus is
  generic (
    seed_1 : unsigned(63 downto 0);            --! first seed
    seed_0 : unsigned(63 downto 0)             --! second seed
    );
  port (
    clk    : in  std_logic;                    --! clock
    rstn   : in  std_logic;                    --! negative reset
    enable : in  std_logic;                    --! enable
    dout   : out std_logic_vector(63 downto 0) --! 64 bit uniform output
    );

end entity;

architecture beh of xoroshiro128plus is
  signal s_0 : std_logic_vector(63 downto 0);
  signal s_1 : std_logic_vector(63 downto 0);
begin

  dout <= std_logic_vector(unsigned(s_0) + unsigned(s_1));

  ctrl : process (clk, rstn)
    variable s_1n : std_logic_vector(63 downto 0);
  begin
    if rstn = '0' then
      s_0 <= std_logic_vector(seed_0);
      s_1 <= std_logic_vector(seed_1);
    elsif rising_edge(clk) and enable = '1' then
      s_1n := s_1 xor s_0;
      s_0  <= std_logic_vector((unsigned(s_0) rol 24) xor unsigned(s_1n) xor (unsigned(s_1n) sll 16));
      s_1  <= std_logic_vector(unsigned(s_1n) rol 37);
    end if;
  end process ctrl;

end architecture beh;
