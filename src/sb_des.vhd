library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sb_des is
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
end sb_des;

architecture beh of sb_des is
    
    signal r_en_last    : std_logic;
    signal r_updated    : std_logic;
    signal r_din        : std_logic_vector(DEPTH - 1 downto 0);
    signal r_dout       : std_logic_vector(DEPTH - 1 downto 0);
    
begin

    dout <= r_dout;
    updated <= r_updated;

    process (clk, rstn)
    begin
        if rstn = '0' then
            r_en_last <= '0';
            r_din <= (others => '0');
            r_dout <= (others => '0');
            r_updated <= '0';
        elsif rising_edge(clk) then
            if sb_en = '1' then
                r_din <= r_din(DEPTH-2 downto 0) & sb_data;
                r_updated <= '0';
            elsif r_en_last = '1' then
                r_dout <= r_din;
                r_updated <= '1';
            else
                r_updated <= '0';
            end if;
            
            r_en_last <= sb_en;
        end if;
    end process;

end beh;
