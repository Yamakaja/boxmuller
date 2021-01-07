--------------------------------------------------------------------------------
--! @file
--! @brief Box-Mueller transformator
--! @author David Winter
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Implements the box-mueller transformation to create a gaussian distribution
--! from uniformly distributed bits.
--! At the time of writing this documentation, this transform had a throughput
--! of one output (i.e. two normal variables) per clock cycle, and a pipeline
--! depth of 30 clock cycles.
--!
--! For more information on the architecture of this core:
--! D. -. Lee, J. D. Villasenor, W. Luk and P. H. W. Leong, "A hardware Gaussian
--! noise generator using the Box-Muller method and its error analysis," in IEEE
--! Transactions on Computers, vol. 55, no. 6, pp. 659-671, June 2006,
--! doi: 10.1109/TC.2006.81.
entity boxmueller is
    port ( 
        clk  : in std_logic;                         --! Data clock
        rstn : in std_logic;                         --! Negative reset
        u    : in std_logic_vector(95 downto 0);     --! Uniform random input
        x_0  : out signed(15 downto 0);              --! First output normal variable   bit value: (5,11)
        x_1  : out signed(15 downto 0)               --! Second output normal variable  bit value: (5,11)
    );
end boxmueller;

architecture beh of boxmueller is

    -- Component definitions
    
    component lzd_48 is
        port (
            clk : in STD_LOGIC;
            rstn : in STD_LOGIC;
            en : in STD_LOGIC;
            din : in STD_LOGIC_VECTOR (47 downto 0);
            p : out unsigned (5 downto 0)
        );
    end component;
    
    component lzd_32 is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            en : in std_logic;
            din : in std_logic_vector(31 downto 0);
            p : out unsigned(4 downto 0);
            v : out std_logic
        );
    end component;

    component pp_fcn_ln is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            x : in unsigned(30 downto 0);
            y_e : out unsigned(26 downto 0)
       );
    end component;
    
    component pp_fcn_sqrt is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            x : in std_logic_vector(7+13-1 downto 0);
            y : out unsigned(16 downto 0)
       );
    end component;
    
    component pp_fcn_trig is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            x : in std_logic_vector(13 downto 0);
            y_sin : out signed(17 downto 0);
            y_cos : out signed(17 downto 0)
        );
    end component;
    
    component shifter_lr is
        generic (
            DATA_WIDTH : integer := 16;
            CONTROL_WIDTH : integer := 5;
            C_SHIFT : integer := 0
        );
        port ( clk : in STD_LOGIC;
            rstn : in STD_LOGIC;
            en : in STD_LOGIC;
            din : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
            c : in signed(CONTROL_WIDTH-1 downto 0);
            dout : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
        );
    end component;

    -- Input registers
    signal r_i_u_0  : std_logic_vector(47 downto 0);
    signal r_i_u_1  : std_logic_vector(15 downto 0);
    signal r_i_u_2  : std_logic_vector(30 downto 0);
    
    -- e = -2*ln(u_0)
    signal w_e_p    : unsigned(5 downto 0);
    signal w_e_y    : unsigned(26 downto 0);
    
    signal r_e_exp  : signed(6 downto 0);
    
    constant LN2    : signed(26 downto 0) := to_signed(46516319, 27); -- = ln(2) * 2^26
    signal r_e_exp_ln : signed((LN2'length + r_e_exp'length) - 1 downto 0);
    signal r_e_y    : signed(r_e_exp_ln'range);
    
    signal r_e_int  : signed(r_e_exp_ln'range);
    
    signal r_e      : signed(7+24-1 downto 0);
    
    
    -- f = sqrt(e)
    
    signal w_f_lzd_i : std_logic_vector(31 downto 0);
    
    signal r_f_e_0  : signed(r_e'range);
    signal w_f_p    : unsigned(4 downto 0);
    
    signal r_f_exp  : signed(5 downto 0);
    type exp_delay_t is array(0 to 8) of signed(r_f_exp'range);
    signal r_f_exp_d : exp_delay_t;
    signal r_f_e_1  : signed(r_e'range);

    signal w_f_x    : std_logic_vector(r_e'range);
    signal r_f_x    : std_logic_vector(24 downto 0);
    
    signal w_f_y    : unsigned(16 downto 0);
    signal r_f_y    : unsigned(20-1 downto 0);
    
    signal w_f      : std_logic_vector(r_f_y'range);
    signal r_f      : signed(5+13-1 downto 0);
    
    -- sin/cos
    signal r_t_quad : unsigned(1 downto 0);
    signal w_t_sin  : signed(17 downto 0);
    signal w_t_cos  : signed(17 downto 0);
    signal r_t_g_0  : signed(17 downto 0);
    signal r_t_g_1  : signed(17 downto 0);
    
    signal r_x_0  : signed(r_t_g_0'length + r_f'length - 1 downto 0);
    signal r_x_1  : signed(r_t_g_0'length + r_f'length - 1 downto 0);
begin
    process (clk)
        variable quad : integer range 0 to 3;
    begin
        if rising_edge(clk) then
            -- Buffer input
            r_i_u_0 <= u(48 downto 1);
            r_i_u_1 <= u(64 downto 49);
            r_i_u_2 <= u(95 downto 65);
            
            -- ln
            r_e_exp <= signed('0' & std_logic_vector(w_e_p)) + 1;
            
            r_e_y <= signed("00000000" & std_logic_vector(w_e_y(w_e_y'length-1 downto 1)));
            r_e_exp_ln <= r_e_exp * LN2;
            
            r_e_int <= (r_e_exp_ln - r_e_y);
            
            r_e <= r_e_int(r_e_int'length-3 downto 1);
            
            -- sqrt
            r_f_e_0 <= r_e;
            
            r_f_e_1 <= r_f_e_0;
            r_f_exp <= signed('0' & std_logic_vector(w_f_p)) - 6;
            
            r_f_exp_d(0) <= r_f_exp;
            for i in 1 to r_f_exp_d'length-3 loop
                r_f_exp_d(i) <= r_f_exp_d(i-1);
            end loop;
            
            r_f_exp_d(7) <= -r_f_exp_d(6);
            
            if r_f_exp_d(7)(0) = '1' then
                r_f_exp_d(8) <= r_f_exp_d(7) - 1;
            else
                r_f_exp_d(8) <= r_f_exp_d(7);
            end if;
            
            r_f_x <= r_f_exp_d(2)(0) & w_f_x(23 downto 0);
            
            r_f_y <= "000" & w_f_y;
            r_f <= signed('0' & w_f(w_f'length - 1 downto w_f'length - (r_f'length - 1)));
            
            -- sin/cos
            
            r_t_quad <= unsigned(r_i_u_1(15 downto 14));
            
            quad := to_integer(r_t_quad);
            case quad is
                when 0 =>
                    r_t_g_0 <= w_t_sin;
                    r_t_g_1 <= w_t_cos;
                when 1 =>
                    r_t_g_0 <= w_t_cos;
                    r_t_g_1 <= -w_t_sin;
                when 2 =>
                    r_t_g_0 <= -w_t_sin;
                    r_t_g_1 <= -w_t_cos;
                when 3 =>
                    r_t_g_0 <= -w_t_cos;
                    r_t_g_1 <= w_t_sin;
            end case;
            
            r_x_0 <= r_f * r_t_g_0;
            r_x_1 <= r_f * r_t_g_1;
            
        end if;
    end process;
    
    x_0 <= r_x_0(r_x_0'length - 3 downto r_x_0'length - x_0'length - 2);
    x_1 <= r_x_1(r_x_1'length - 3 downto r_x_0'length - x_0'length - 2);
    
    w_f_lzd_i <= std_logic_vector(r_e) & '1';
    
    lzd_f : lzd_32
        port map (
            clk => clk,
            rstn => rstn,
            en => '1',
            din => w_f_lzd_i,
            p => w_f_p
            );
            
    f_range_red : shifter_lr
         generic map (
             DATA_WIDTH => r_e'length,
             CONTROL_WIDTH => r_f_exp'length
         )
         port map (
             clk => clk,
             rstn => rstn,
             en => '1',
             din => std_logic_vector(r_f_e_1),
             c => r_f_exp,
             dout => w_f_x
         );
         
    f_range_rec : shifter_lr
         generic map (
             DATA_WIDTH => r_f_y'length,
             CONTROL_WIDTH => r_f_exp'length,
             C_SHIFT => 1
         )
         port map (
             clk => clk,
             rstn => rstn,
             en => '1',
             din => std_logic_vector(r_f_y),
             c => r_f_exp_d(8),
             dout => w_f
         );
    
    -- NOTE: lzd_48 and pp_fcn_ln have different pipeline depths!
    --       We can conveniently ignore that, because u_0 and u_2 are
    --       independent!
    
    lzd_e : lzd_48
        port map (
            clk => clk,
            rstn => rstn,
            en => '1',
            din => r_i_u_0,
            p => w_e_p
        );
        
    ln : pp_fcn_ln
        port map (
            clk => clk,
            rstn => rstn,
            x => unsigned(r_i_u_2),
            y_e => w_e_y
       );
       
    sqrt : pp_fcn_sqrt
       port map (
           clk => clk,
           rstn => rstn,
           x => r_f_x(r_f_x'length - 1 downto r_f_x'length - 20),
           y => w_f_y
       );
       
    trig : pp_fcn_trig
        port map (
            clk => clk,
            rstn => rstn,
            x => r_i_u_1(13 downto 0),
            y_sin => w_t_sin,
            y_cos => w_t_cos
        );
        
end beh;
