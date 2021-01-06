library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg.all;

entity top is
    port ( 
        clk     : in STD_LOGIC;
        rstn    : in STD_LOGIC;
--         d       : out std_logic_vector(26 downto 0);
        x_0     : out std_logic_vector(15 downto 0);
        x_1     : out std_logic_vector(15 downto 0)
   );
           -- din : in std_logic_vector(31 downto 0);
           -- c : in std_logic_vector(4 downto 0);
           -- dout : out std_logic_vector(31 downto 0));
end top;

architecture beh of top is
    
--    component lzd_48
--        port (  clk : in std_logic;
--            rstn : in std_logic;
--            en : in std_logic;
--            din : in std_logic_vector(47 downto 0);
--            p : out unsigned(5 downto 0));
--    end component;
    -- component pp_fcn_ln is
    -- port ( clk : in std_logic;
    --        rstn : in std_logic;
    --        x : in unsigned(30 downto 0);
    --        y_e : out unsigned(26 downto 0)
    --        );
    -- end component;
    
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
    
    component boxmueller is
    port ( clk  : in std_logic;
           rstn : in std_logic;
           u    : in std_logic_vector(95 downto 0);
           x_0  : out signed(15 downto 0);
           x_1  : out signed(15 downto 0)
           );
   end component;

--    component shifter_lr
--        generic (
--           data_width : integer := 16;
--           control_width : integer := 5
--           );
--        port ( clk : in STD_LOGIC;
--           rstn : in STD_LOGIC;
--           en : in STD_LOGIC;
--           din : in STD_LOGIC_VECTOR (data_width - 1 downto 0);
--           c : in signed(control_width-1 downto 0);
--           dout : out STD_LOGIC_VECTOR (data_width - 1 downto 0));
--    end component;
--    
--    component shifter_l
--        generic (
--           data_width : integer := 16;
--           control_width : integer := 4
--           );
--        port ( clk : in STD_LOGIC;
--           rstn : in STD_LOGIC;
--           en : in STD_LOGIC;
--           din : in STD_LOGIC_VECTOR (data_width - 1 downto 0);
--           c : in unsigned(control_width-1 downto 0);
--           dout : out STD_LOGIC_VECTOR (data_width - 1 downto 0));
--    end component;
--    
--    signal w_c : unsigned(4 downto 0);

    -- component xbip_multadd_0
    --     PORT (
    --         CLK : IN STD_LOGIC;
    --         CE : IN STD_LOGIC;
    --         SCLR : IN STD_LOGIC;
    --         A : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    --         B : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    --         C : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    --         SUBTRACT : IN STD_LOGIC;
    --         P : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
    --         PCOUT : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    --     );
    -- end component;
    -- 
    -- component mult_gen_0
    --     PORT (
    --         CLK : IN STD_LOGIC;
    --         A : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    --         B : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    --         P : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    --       );
    -- end component;
    
    -- signal ri_a : signed(23 downto 0);
    -- signal ri_b : signed(23 downto 0);
    -- signal ri_c : signed(47 downto 0);
    -- 
    -- 
    -- signal r0_c : signed(47 downto 0);
    -- signal r0_d : std_logic_vector(47 downto 0);
    -- 
    -- signal r_d : signed(47 downto 0);
    
    signal u : std_logic_vector(127 downto 0);
    
    signal y : unsigned(26 downto 0);
    
    signal w_x_0 : signed(15 downto 0);
    signal w_x_1 : signed(15 downto 0);
begin

    -- d <= std_logic_vector(y);
    
    x_0 <= std_logic_vector(w_x_0);
    x_1 <= std_logic_vector(w_x_1);
    
    rand_0 : xoroshiro128plus
        generic map (
            seed_1 => X"1976c51ab89a5886",
            seed_0 => X"86114fc94d6c4ad5"
            )
        port map (
            clk    => clk,
            rstn   => rstn,
            enable => '1',
            dout   => u(127 downto 64)
        );
    
    rand_1 : xoroshiro128plus
        generic map (
            seed_1 => X"e0296ce69151a79f",
            seed_0 => X"99ee2d06176445b6"
        )
        port map (
            clk    => clk,
            rstn   => rstn,
            enable => '1',
            dout   => u(63 downto 0)
        );
    
    bm : boxmueller
        port map (
            clk  => clk,
            rstn => rstn,
            u    => u(95 downto 0),
            x_0  => w_x_0,
            x_1  => w_x_1
        );

    -- ln : pp_fcn_ln
    --     port map ( clk => clk,
    --        rstn => rstn,
    --        x => unsigned(rnd_out(rnd_out'length-1 downto rnd_out'length-31)),
    --        y_e => y);

    -- MULTADD : xbip_multadd_0
    --     port map (
    --         CLK => clk,
    --         CE => '1',
    --         SCLR => '0',
    --         A => a,
    --         B => b,
    --         C => c,
    --         SUBTRACT => '0',
    --         P => d);

    process (clk)
    begin
    
--        if rstn = '0' then
--            ri_a <= (others => '0');
--            ri_b <= (others => '0');
--            ri_c <= (others => '0');
--            
--            r0_c <= (others => '0');
--            r0_d <= (others => '0');
--            
--            r_d <= (others => '0');
--        elsif rising_edge(clk) then
        if rising_edge(clk) then
--            ri_a <= signed(a);
--            ri_b <= signed(b);
            -- ri_c <= signed(c);
--          --   
--          --   r0_d <= ri_a * ri_b;
            -- r0_c <= ri_c;
--          --   
            -- r_d <= signed(r0_d) + r0_c;
            
        end if;
    end process;
    
    -- MULT : mult_gen_0
    --     port map (
    --         CLK => clk,
    --         A => a,
    --         B => b,
    --         P => r0_d
    --       );
    -- 
    -- d <= std_logic_vector(r_d);

--    LZD : lzd_48
--        port map (
--            clk => clk,
--            rstn => rstn,
--            en => '1',
--            din => data,
--            p => w_dout);

--    SHFT : shifter_l
--        generic map (
--            data_width => 32,
--            control_width => 5)
--        port map(
--            clk => clk,
--            rstn => rstn,
--            en => '1',
--            din => din,
--            c => w_c,
--            dout => dout
--            );
--            
--    w_c <= unsigned(c);
    
end beh;
