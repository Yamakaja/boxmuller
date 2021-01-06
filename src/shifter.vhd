library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shifter_lr is
    generic (
           DATA_WIDTH    : integer := 16;
           CONTROL_WIDTH : integer := 5;
           C_SHIFT       : integer := 0
           );
    port ( clk : in STD_LOGIC;
           rstn : in STD_LOGIC;
           en : in STD_LOGIC;
           din : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           c : in signed(CONTROL_WIDTH-1 downto 0);
           dout : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end shifter_lr;

architecture beh of shifter_lr is
    -- Stage: Preprocessing
    signal r_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal r_neg : std_logic;
    signal r_c : unsigned(CONTROL_WIDTH - 1 downto 0);
    
    -- Stage: shift_0
    signal r_data_0 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal r_neg_0 : std_logic;
    
    -- Stage: output
    signal r_dout : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    function reverse_vector (a: in std_logic_vector)
            return std_logic_vector is
        variable result: std_logic_vector(a'RANGE);
        alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
    begin
        for i in aa'RANGE loop
            result(i) := aa(i);
        end loop;
        return result;
    end;
begin

    preprocessing: process(clk, rstn)
    begin
        if rstn = '0' then
            r_data <= (others => '0');
            r_neg <= '0';
            r_c <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                if c(CONTROL_WIDTH - 1) = '0' then
                    r_data <= din;
                    r_c <= unsigned(std_logic_vector(c)) srl C_SHIFT;
                    r_neg <= '0';
                else
                    r_data <= reverse_vector(din);
                    r_neg <= '1';
                    r_c <= unsigned(std_logic_vector(-c)) srl C_SHIFT;
                end if;
            end if;
        end if;
    end process;
    
    shift : process(clk, rstn)
    begin
        if rstn = '0' then
            r_data_0 <= (others => '0');
            r_neg_0 <= '0';
        elsif rising_edge(clk) then
            if en = '1' then
                r_neg_0 <= r_neg;
                r_data_0 <= std_logic_vector(unsigned(r_data) sll to_integer(r_c));
            end if;
        end if;
    end process;
    
    postprocessing: process(clk, rstn)
    begin
        if rstn = '0' then
            r_dout <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                if r_neg_0 = '0' then
                    r_dout <= r_data_0;
                else
                    r_dout <= reverse_vector(r_data_0);
                end if;
            end if;
        end if;
    end process;
    
    dout <= r_dout;
end beh;




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shifter_l is
    generic (
           DATA_WIDTH : integer := 16;
           CONTROL_WIDTH : integer := 4
           );
    port ( clk : in STD_LOGIC;
           rstn : in STD_LOGIC;
           en : in STD_LOGIC;
           din : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           c : in unsigned(CONTROL_WIDTH-1 downto 0);
           dout : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end shifter_l;

architecture beh of shifter_l is

    -- Stage: output
    signal r_dout : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
begin
    
    shift : process(clk, rstn)
    begin
        if rstn = '0' then
            r_dout <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                r_dout <= std_logic_vector(unsigned(din) sll to_integer(c));
            end if;
        end if;
    end process;
    
    dout <= r_dout;
end beh;
