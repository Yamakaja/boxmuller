--------------------------------------------------------------------------------
--! @file
--! @brief Bux-Mueller output remapper/scaler
--! @author David Winter
--------------------------------------------------------------------------------
--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;

--! Used to transform a normal distribution with mu=0, sigma=1 to
--! a normal distribution with mu=offset, sigma=factor.
--! Finally, the output is clipped to 6 bits and truncated to 8
--! bits.
entity output_remapper is
    port (
        clk : in std_logic;
        rstn : in std_logic;
        en   : in std_logic;
        din    : in signed (15 downto 0); -- 5,11
        factor : in signed (15 downto 0); -- 8,8
        offset : in signed (7 downto 0);  -- 6,2
        dout   : out signed(7 downto 0)
    );
end output_remapper;

architecture beh of output_remapper is
    signal r_0_din : signed(din'range);
    signal r_0_factor : signed(factor'range);
    signal r_0_offset : signed(offset'range);
    
    signal r_1_din : signed(din'range);
    signal r_1_factor : signed(factor'range);
    signal r_1_offset : signed(offset'range);

    signal r_2_y      : signed(r_0_din'length + r_0_factor'length - 1 downto 0); -- 13,19 / 32
    signal r_2_offset : signed(r_2_y'range);
    
    signal r_3_y      : signed(r_2_y'range);
    
    signal r_4_y      : signed(13+2-1 downto 0); -- 13,19
    
    signal r_5_y      : signed(7 downto 0);
    
begin

    dout <= r_5_y;

    process (clk, rstn)
    begin
        if rising_edge(clk) and en = '1' then
            r_0_din <= din;
            r_0_factor <= factor;
            r_0_offset <= offset;
            
            r_1_din <= r_0_din;
            r_1_factor <= r_0_factor;
            r_1_offset <= r_0_offset;
            
            r_2_y <= r_1_din * r_1_factor;
            r_2_offset <= (others => '0');
            r_2_offset(17 + r_1_offset'length-1 downto 17) <= r_1_offset;
            
            r_3_y <= r_2_y + r_2_offset;
            
            r_4_y <= r_3_y(r_3_y'length - 1 downto r_3_y'length - r_4_y'length);
            
            if r_4_y(r_4_y'left) = '0' then
                if r_4_y(r_4_y'left-1 downto 5) = 0 then
                    r_5_y <= r_4_y(r_5_y'range);
                else
                    r_5_y <= to_signed(31, 8);
                end if;
            else
                if r_4_y(r_4_y'left-1 downto 5) = -1 then
                    r_5_y <= r_4_y(r_5_y'range) + 1;
                else
                    r_5_y <= to_signed(-31, 8);
                end if;
            end if;
            
        end if;
    end process;
    
end beh;
