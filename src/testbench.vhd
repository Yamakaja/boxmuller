library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg;

entity testbench is
end testbench;

architecture beh of testbench is
    signal t_clk : std_logic := '0';
    signal t_rstn : std_logic := '0';
    signal t_en : std_logic := '0';
    
    signal t_dout : std_logic_vector(127 downto 0);
    
    signal t_x_0 : signed(15 downto 0);
    signal t_x_1 : signed(15 downto 0);
    
    -- signal t_p : unsigned(5 downto 0);
    -- 
    -- signal t_y_e : unsigned(26 downto 0);
    -- 
    -- signal t_y_sin : signed(17 downto 0);
    -- signal t_y_cos : signed(17 downto 0);
    -- 
    -- signal t_y : unsigned(16 downto 0);
    -- signal t_x_r : unsigned(18 downto 0);
    -- 
    -- signal t_x_trig : unsigned(13 downto 0);
    -- 
    -- 
    -- signal t_shift_c : signed(5 downto 0)               := to_signed(-16, 6);
    -- signal t_shift_dout : std_logic_vector(31 downto 0) := (others => '0');
    
    -- component lzd_48
    --     port (  clk : in std_logic;
    --         rstn : in std_logic;
    --         en : in std_logic;
    --         din : in std_logic_vector(47 downto 0);
    --         p : out unsigned(5 downto 0));
    -- end component;
    -- 
    -- component shifter_lr
    -- generic (
    --        data_width : integer := 16;
    --        control_width : integer := 5
    --        );
    -- port ( clk : in STD_LOGIC;
    --        rstn : in STD_LOGIC;
    --        en : in STD_LOGIC;
    --        din : in STD_LOGIC_VECTOR (data_width - 1 downto 0);
    --        c : in signed(control_width-1 downto 0);
    --        dout : out STD_LOGIC_VECTOR (data_width - 1 downto 0));
    -- end component;
    -- 
    -- component pp_fcn_ln is
    -- port ( clk : in std_logic;
    --        rstn : in std_logic;
    --        x : in unsigned(30 downto 0);
    --        y_e : out unsigned(26 downto 0)
    --        );
    -- end component;
    -- 
    -- component pp_fcn_sqrt is
    -- port ( clk : in std_logic;
    --        rstn : in std_logic;
    --        x : in std_logic_vector(7+13-1 downto 0);
    --        y : out unsigned(16 downto 0)
    --        );
    -- end component;
    -- 
    -- component pp_fcn_trig is
    --     port (
    --         clk : in std_logic;
    --         rstn : in std_logic;
    --         x : in std_logic_vector(13 downto 0);
    --         y_sin : out signed(17 downto 0);
    --         y_cos : out signed(17 downto 0)
    --     );
    -- end component;
    
    component boxmueller is
        port ( 
            clk  : in std_logic;
            rstn : in std_logic;
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
        
begin
    
    rand_0 : xoroshiro128plus
        generic map (
            seed_1 => X"1976c51ab89a5886",
            seed_0 => X"86114fc94d6c4ad5"
            )
        port map (
            clk    => t_clk,
            rstn   => t_rstn,
            enable => t_en,
            dout   => t_dout(127 downto 64)
        );
    
    rand_1 : xoroshiro128plus
        generic map (
            seed_1 => X"e0296ce69151a79f",
            seed_0 => X"99ee2d06176445b6"
        )
        port map (
            clk    => t_clk,
            rstn   => t_rstn,
            enable => t_en,
            dout   => t_dout(63 downto 0)
        );
    
    bm : boxmueller
        port map ( 
            clk  => t_clk,
            rstn => t_rstn,
            u    => t_dout(95 downto 0),
            x_0  => t_x_0,
            x_1  => t_x_1
        );
    
    t_clk <= not t_clk after 5 ns;
    t_rstn <= '1' after 3 ns;
    
    seq : process
    begin
        -- wait for 309 ns;
        wait for 9 ns;
        t_en <= '1';
        wait for 10 ns;
        t_en <= '0';
        wait for 1 ns;
        
        wait for 500 ns;
    --     t_din <= (47 => '1', others => '0');
    --     wait for 22 ns;
    --     
    --     for i in 0 to 47 loop
    --         t_din <= '0' & t_din(47 downto 1);
    --         wait for 10 ns;
    --     end loop;
    --     
    --     t_din <= (16 => '1', others => '0');
    --     wait for 10 ns;
    --     
    --     for i in 0 to 31 loop
    --         t_shift_c <= t_shift_c + 1;
    --         wait for 10 ns;
    --     end loop;
    --     
    --     t_din <= "100010111011100100001011001011010011001111100101";
    --     
    --     wait for 5 ms;
    end process seq;
    
end beh;
