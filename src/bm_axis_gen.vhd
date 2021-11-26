library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity bm_axis_gen is
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
end bm_axis_gen;

architecture beh of bm_axis_gen is
    
    signal r_valid_counter  : unsigned(COUNTER_WIDTH - 1 downto 0);
    constant VALID_COUNTER_MAX : unsigned(r_valid_counter'range) := (others => '1');
    signal r_axis_data      : std_logic_vector(din'range);
    signal r_axis_valid     : std_logic;
    
    signal w_input_valid    : std_logic;
    
begin

    w_input_valid <= '0' when r_valid_counter /= VALID_COUNTER_MAX else '1';
    -- sub_en <= not w_input_valid or en; -- Too slow
    sub_en <= en;
    
    s_axis_tvalid <= r_axis_valid;
    s_axis_tdata <= r_axis_data;

    input_handler : process (clk, rstn)
    begin
        if rstn = '0' then
            r_valid_counter <= (others => '0');
        elsif rising_edge(clk) and en = '1' then
            if updated = '1' then
                 r_valid_counter <= (others => '0');
             elsif w_input_valid = '0' then
                 r_valid_counter <= r_valid_counter + 1;
            end if;
        end if;
    end process;
    
    output_handler : process (clk, rstn)
        variable data_valid : std_logic := '0';
    begin
        if rstn = '0' then
            r_axis_data <= (others => '0');
            r_axis_valid <= '0';
        elsif rising_edge(clk) then
            data_valid := r_axis_valid;
            
            if r_axis_valid = '1' then
                if s_axis_tready = '1' then
                    data_valid := '0';
                end if;
            end if;
            
            if en = '1' and w_input_valid = '1' and data_valid = '0' then
                r_axis_data <= din;
                data_valid := '1';
            end if;
            
            r_axis_valid <= data_valid;
        end if;
    end process;

end beh;
