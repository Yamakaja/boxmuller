--------------------------------------------------------------------------------
--! @file
--! @brief Partial polynomial approximations of sqrt, ln, and sin/cos.
--! @author David Winter
--------------------------------------------------------------------------------
--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! Floating point math, only used at "compile"-time.
use ieee.math_real.all;

--! Import ROM constants.
use work.pp_fcn_rom_pkg.all;

--! Implements a partial polynomial approximation of \f$\ln(x)\f$
--! where \f$ x \in [1,2) \f$.
--! The approximation uses 256 individual polynomials of degree 2
--! with an output error in the order of \f$\approx 10^{-9}\f$
--!
--! Throughput: 1 sample/cycle.
--! Delay:      11 cycles.
entity pp_fcn_ln is
    port ( clk : in std_logic;                  --! Clock input
           rstn : in std_logic;                 --! Inverted reset
           x : in unsigned(31-1 downto 0);      --! Input. bit value: (0,31)  \\Rightarrow x \\in [0,1) . (The leading one-bit is *implicit*!).
           y_e : out unsigned(26 downto 0)      --! Output. bit value: (0,27) \\Rightarrow x \\in [0,1).
           );
end pp_fcn_ln;

architecture beh of pp_fcn_ln is
    constant DEGREE         : integer := 2;                                         --! Polynomial degree
    constant NSEGMETNS      : integer := 256;                                       --! Polynomial section count
    constant LOG_NSEGMENTS  : integer := integer(ceil(log2(real(NSEGMETNS))));      --! log2(Polynomial section count)
    
    constant X_FRAC_LENGTH  : integer := x'length-LOG_NSEGMENTS;                    --! Amount of input bits that will be used in polynomial computation 
    
    type coeff_widths_t is array(0 to DEGREE) of integer;
    constant COEFF_WIDTHS   : coeff_widths_t := (31, 23, 14);                       --! The polynomial coefficient bit widths
    
    type poly_widths_t is array(0 to DEGREE) of integer;
    constant POLY_WIDTHS    : poly_widths_t := (COEFF_WIDTHS(0), COEFF_WIDTHS(0) + COEFF_WIDTHS(1), COEFF_WIDTHS(0) + COEFF_WIDTHS(1) + COEFF_WIDTHS(2)); --! The polynomial bit with = a running sum of coefficient widths
    
    signal LOG_COEFF_TABLE  : log_coeff_table_t := LOG_COEFF_TABLE_DATA;            --! Polynomial lookup table, implemented as "block ram"-rom.
    attribute rom_style     : string;
    attribute rom_style of LOG_COEFF_TABLE : signal is "block";                     --! Force block ram usage
    
    --! Wide multiplication core provided by Xilinx (More efficient/controlled than the inferred multiplier)
    component mult_23_23_24 IS
        PORT (
            CLK : IN STD_LOGIC;
            A : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
            P : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
            );
    end component;
    
    -- Input Accessors
    signal w_x_B        : unsigned(LOG_NSEGMENTS-1 downto 0);                       --! Wire to the most significant LOG_NSEGMENTS input bits
    signal w_x_A        : unsigned(X_FRAC_LENGTH-1 downto 0);                       --! Wire to the input fraction
    
    -- Buffer Stage
    signal r_i_x        : signed(COEFF_WIDTHS(1)-1 downto 0);                       --! Input fraction buffer
    signal r_i_coeffs   : std_logic_vector(POLY_WIDTHS(2) - 1 downto 0);            --! Coefficient buffer register
    
    signal r_0_x        : signed(COEFF_WIDTHS(1)-1 downto 0);                       --! Input fraction buffer
    signal r_0_coeffs   : std_logic_vector(POLY_WIDTHS(1) - 1 downto 0);            --! Coefficient buffer register; coefficient 0 and 1
    signal r_0_c_2      : signed(COEFF_WIDTHS(2)-1 downto 0);                       --! Coefficient 2 buffer register
    
    signal r_d_x        : signed(COEFF_WIDTHS(1)-1 downto 0);                       --! Input fraction buffer; pulled into DSP slice
    signal r_d_coeffs   : std_logic_vector(POLY_WIDTHS(1) - 1 downto 0);            --! Coefficient buffer register; coefficient 0 and 1
    signal r_d_c_2      : signed(COEFF_WIDTHS(2)-1 downto 0);                       --! Coefficient 2 buffer register; pulled into DSP slice

    signal r_1_x        : signed(COEFF_WIDTHS(1)-1 downto 0);                       --! Input fraction buffer
    signal r_1_y        : signed(2*(COEFF_WIDTHS(2)) - 1 downto 0);                 --! DSP output buffer register
    signal r_1_coeffs   : std_logic_vector(POLY_WIDTHS(0) - 1 downto 0);            --! Coefficient 0 buffer
    signal r_1_c_1      : signed(COEFF_WIDTHS(1) + COEFF_WIDTHS(2) - 1 downto 0);   --! Coefficient 1 buffer; extended to account for multiplicative shift; pulled into DSP slice
    
    signal r_2_x        : signed(COEFF_WIDTHS(1)-1 downto 0);                       --! Input fraction buffer
    signal r_2_y        : signed(COEFF_WIDTHS(1) + COEFF_WIDTHS(2) - 1 downto 0);   --! DSP output buffer register
    signal r_2_coeffs   : std_logic_vector(POLY_WIDTHS(0) - 1 downto 0);            --! Coefficient 0 buffer
    
    -- Multiplier Output Stage
    signal w_3_y        : std_logic_vector(COEFF_WIDTHS(1) downto 0);               --! Multiplier output wire
    signal w_3_a        : std_logic_vector(22 downto 0);                            --! Multiplier input wire
    
    -- Multiplier coefficient delay stage
    constant MULT_STAGES : integer := 4;                                            --! Multiplier ip pipeline depth
    type coeff_delay_t is array(0 to MULT_STAGES-1) of std_logic_vector(COEFF_WIDTHS(0)-1 downto 0);
    signal w_3_c_0 : coeff_delay_t;
    
    -- Output
    signal r_o : signed(COEFF_WIDTHS(0)-1 downto 0);                                --! Output buffer
    
begin
    
    mult : mult_23_23_24
        port map (
            CLK => clk,
            A => w_3_a,
            B => std_logic_vector(r_2_x),
            P => w_3_y
        );
    
    w_x_B <= x(x'length-1 downto X_FRAC_LENGTH);
    w_x_A <= x(X_FRAC_LENGTH-1 downto 0);
    
    w_3_a <= std_logic_vector(r_2_y(r_2_y'length-2 downto r_2_y'length - COEFF_WIDTHS(1) - 1));
    y_e <= unsigned(std_logic_vector(r_o(r_o'length-2 downto r_o'length-1-y_e'length)));
    
    process (clk)
    begin
        if rising_edge(clk) then
            -- Fetch Operands
            r_i_x <= signed('0' & std_logic_vector(w_x_A(w_x_A'length-1 downto w_x_A'length-(r_i_x'length-1))));
            r_i_coeffs <= LOG_COEFF_TABLE(to_integer(w_x_B));
            
            -- Load operands
            r_0_x <= r_i_x;
            r_0_coeffs <= r_i_coeffs(POLY_WIDTHS(1)-1 downto 0);
            r_0_c_2 <= signed(r_i_coeffs(POLY_WIDTHS(2)-1 downto POLY_WIDTHS(1)));
            
            -- DSP Input Buffer Stage
            r_d_x <= r_0_x;
            r_d_coeffs <= r_0_coeffs;
            r_d_c_2 <= r_0_c_2;
            
            -- eta_2 = C_2 * x
            r_1_x <= r_d_x;
            r_1_coeffs <= r_d_coeffs(POLY_WIDTHS(0)-1 downto 0);
            r_1_y <= r_d_c_2 * r_d_x(r_d_x'length - 1 downto r_d_x'length - COEFF_WIDTHS(2));
            
            r_1_c_1(r_1_c_1'length-1) <= '0';
            r_1_c_1(r_1_c_1'length-2 downto r_1_c_1'length-COEFF_WIDTHS(1)-1) <= signed(r_d_coeffs(POLY_WIDTHS(1)-1 downto POLY_WIDTHS(0)));
            r_1_c_1(COEFF_WIDTHS(2)-1-1 downto 0) <= (others => '0');
            
            -- eta_1 = eta_2 + C_1
            r_2_x <= r_1_x;
            r_2_y <= r_1_y + r_1_c_1;
            r_2_coeffs <= r_1_coeffs;
            
            w_3_c_0(0) <= r_2_coeffs;
            for i in 1 to w_3_c_0'length-1 loop
                w_3_c_0(i) <= w_3_c_0(i-1); 
            end loop;
            
            r_o <= signed(w_3_y) + signed(w_3_c_0(w_3_c_0'length-1));
        end if;
    end process;

end beh;

--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! Floating point math, only used at "compile"-time.
use ieee.math_real.all;

--! Import ROM constants.
use work.pp_fcn_rom_pkg.all;

--! Implements a partial polynomial approximation of \f$\sqrt{x}\f$
--! where \f$ x \in [1,4) \f$.
--! The approximation uses 128 individual polynomials of degree 1
--! with an output error in the order of \f$\approx 10^{-5}\f$
--!
--! \ref pp_fcn_sqrt_x The input \p x is the concatenation of a "multiplier
--! bit", and the actual x value (\\in [0,1)).
--! I.e. if the first bit is 0, the remaining bits will be interpreted as
--! a value \\in [1,2). For a leading bit of 1, the value will be mapped
--! to [2,4).
--!
--! Throughput: 1 sample/cycle.
--! Delay:      4 cycles. (?)
entity pp_fcn_sqrt is
    port ( clk : in std_logic;                          --! Clock input
           rstn : in std_logic;                         --! Inverted reset
           x : in std_logic_vector(7+13-1 downto 0);    --! Input. bit value: (1,0,19)
           y : out unsigned(16 downto 0)                --! Output. bit value: (1, 16)
           );
end pp_fcn_sqrt;

architecture beh of pp_fcn_sqrt is
    constant DEGREE         : integer := 1;
    constant NSEGMETNS      : integer := 128;
    constant LOG_NSEGMENTS  : integer := integer(ceil(log2(real(NSEGMETNS))));
    
    constant X_FRAC_LENGTH  : integer := x'length-LOG_NSEGMENTS;
    
    type coeff_widths_t is array(0 to DEGREE) of integer;
    constant COEFF_WIDTHS   : coeff_widths_t := (19, 13);
    
    type poly_widths_t is array(0 to DEGREE) of integer;
    constant POLY_WIDTHS    : poly_widths_t := (COEFF_WIDTHS(0), COEFF_WIDTHS(0) + COEFF_WIDTHS(1));
    
    signal SQRT_COEFF_TABLE  : sqrt_coeff_table_t := SQRT_COEFF_TABLE_DATA;
    attribute rom_style     : string;
    attribute rom_style of SQRT_COEFF_TABLE : signal is "block";
    
    -- Input Accessors
    signal w_x_B        : std_logic_vector(LOG_NSEGMENTS-1 downto 0);
    signal w_x_A        : std_logic_vector(X_FRAC_LENGTH-1 downto 0);
    
    -- Buffer Stage
    signal r_i_x        : signed(COEFF_WIDTHS(1) downto 0);
    signal r_i_coeffs   : std_logic_vector(POLY_WIDTHS(1) - 1 downto 0);
    
    signal r_0_x        : signed(COEFF_WIDTHS(1)+6-1 downto 0);
    signal r_0_coeffs   : std_logic_vector(POLY_WIDTHS(0) - 1 downto 0);
    signal r_0_c_1      : signed(COEFF_WIDTHS(1)-1 downto 0);
    
    -- signal r_d_x        : signed(COEFF_WIDTHS(1)+6-1 downto 0);
    -- signal r_d_coeffs   : std_logic_vector(POLY_WIDTHS(0) - 1 downto 0);
    -- signal r_d_c_1      : signed(COEFF_WIDTHS(1)-1 downto 0);

    signal r_1_y        : signed(2*(COEFF_WIDTHS(1)) + 6 - 1 downto 0);
    signal r_1_c_0      : signed(COEFF_WIDTHS(0) + COEFF_WIDTHS(1) - 1 downto 0);
    
    signal r_2_y        : signed(COEFF_WIDTHS(0) + COEFF_WIDTHS(1) - 1 downto 0);
    
    -- Output
    signal r_o : unsigned(16 downto 0);
    
begin

    w_x_B <= x(x'length-1 downto X_FRAC_LENGTH);
    w_x_A <= x(X_FRAC_LENGTH-1 downto 0);
    
    y <= r_o;
    
    r_o(16) <= '1';
    r_o(15 downto 0) <= unsigned(std_logic_vector(r_2_y(15+16-1 downto 15)));
    
    process (clk)
    begin
        if rising_edge(clk) then
            -- Fetch Operands
            r_i_x <= signed('0' & std_logic_vector(w_x_A));
            r_i_coeffs <= SQRT_COEFF_TABLE(to_integer(unsigned(w_x_B)));
            
            -- Load operands
            r_0_x(r_0_x'length - 1 downto r_0_x'length - 5) <= (others => '0');
            r_0_x(r_i_x'range) <= r_i_x;
            r_0_coeffs <= r_i_coeffs(POLY_WIDTHS(0)-1 downto 0);
            r_0_c_1 <= signed(r_i_coeffs(POLY_WIDTHS(1)-1 downto POLY_WIDTHS(0)));
            
            -- DSP Input Buffer Stage
            -- r_d_x <= r_0_x;
            -- r_d_coeffs <= r_0_coeffs;
            -- r_d_c_1 <= r_0_c_1;
            
            
            r_1_y <= r_0_c_1 * r_0_x;
            
            r_1_c_0(r_1_c_0'length-1 downto r_1_c_0'length-COEFF_WIDTHS(0)) <= signed(r_0_coeffs);
            r_1_c_0(COEFF_WIDTHS(1)-1 downto 0) <= (others => '0');
            
            
            r_2_y <= r_1_y + r_1_c_0;
        end if;
    end process;

end beh;

--! VHDL standard library
library ieee;
--! Logic primitives and vectors
use ieee.std_logic_1164.all;
--! Fixed width integer primitives
use ieee.numeric_std.all;
--! Floating point math, only used at "compile"-time.
use ieee.math_real.all;

--! Import ROM constants.
use work.pp_fcn_rom_pkg.all;

--! Implements a partial polynomial approximation of \f$\sin(\pi/2*x)\f$
--! and \f$\cos(\pi/2*x)\f$ where \f$ x \in [0,1) \f$.
--! The approximation uses 128 individual polynomials of degree 1
--! with an output error in the order of \f$\approx 10^{-5}\f$
--!
--! Throughput: 1 sample/cycle.
--! Delay:      4 cycles. (?)
entity pp_fcn_trig is
    port (
        clk : in std_logic;                     --! Clock input
        rstn : in std_logic;                    --! Inverted Reset
        x : in std_logic_vector(13 downto 0);   --! Input. bit value: (0,14)
        y_sin : out signed(17 downto 0);        --! sin output. bit value: (2,16)
        y_cos : out signed(17 downto 0)         --! cos output. bit value: (2,16)
    );
end pp_fcn_trig;

architecture beh of pp_fcn_trig is
    constant DEGREE         : integer := 1;
    constant NSEGMETNS      : integer := 128;
    constant LOG_NSEGMENTS  : integer := integer(ceil(log2(real(NSEGMETNS))));
    
    constant X_FRAC_LENGTH  : integer := x'length-LOG_NSEGMENTS; -- 7
    
    type coeff_widths_t is array(0 to DEGREE) of integer;
    constant COEFF_WIDTHS   : coeff_widths_t := (19, 12);
    
    type poly_widths_t is array(0 to 3) of integer;
    constant POLY_WIDTHS    : poly_widths_t := (COEFF_WIDTHS(0), COEFF_WIDTHS(0) + COEFF_WIDTHS(1), 2*COEFF_WIDTHS(0) + COEFF_WIDTHS(1), 2*(COEFF_WIDTHS(0) + COEFF_WIDTHS(1)));
    
    signal TRIG_COEFF_TABLE : trig_coeff_table_t := TRIG_COEFF_TABLE_DATA;
    attribute rom_style     : string;
    attribute rom_style of TRIG_COEFF_TABLE : signal is "block";
    
    -- Input Accessors
    signal w_x_B        : std_logic_vector(LOG_NSEGMENTS-1 downto 0);
    signal w_x_A        : std_logic_vector(X_FRAC_LENGTH-1 downto 0);
    
    -- Buffer Stage
    signal r_i_x        : signed(X_FRAC_LENGTH+1-1 downto 0);
    signal r_i_coeffs   : std_logic_vector(2*POLY_WIDTHS(1) - 1 downto 0);
    
    signal r_0_x        : signed(COEFF_WIDTHS(1)+2-1 downto 0);
    signal r_0_c_1_sin  : signed(COEFF_WIDTHS(1)-1 downto 0);
    signal r_0_c_1_cos  : signed(COEFF_WIDTHS(1)-1 downto 0);
    signal r_0_c_0_sin  : signed(COEFF_WIDTHS(0)-1 downto 0);
    signal r_0_c_0_cos  : signed(COEFF_WIDTHS(0)-1 downto 0);

    
    -- signal r_d_x        : signed(COEFF_WIDTHS(1)+6-1 downto 0);
    -- signal r_d_coeffs   : std_logic_vector(POLY_WIDTHS(0) - 1 downto 0);
    -- signal r_d_c_1      : signed(COEFF_WIDTHS(1)-1 downto 0);

    constant OUT_WIDTH : integer := r_0_x'length + r_0_c_1_cos'length;

    signal r_1_y_sin    : signed(OUT_WIDTH - 1 downto 0);
    signal r_1_y_cos    : signed(OUT_WIDTH - 1 downto 0);
    signal r_1_c_0_sin  : signed(OUT_WIDTH - 1 downto 0);
    signal r_1_c_0_cos  : signed(OUT_WIDTH - 1 downto 0);
    
    signal r_2_y_sin    : signed(OUT_WIDTH - 1 downto 0);
    signal r_2_y_cos    : signed(OUT_WIDTH - 1 downto 0);
    
begin

    w_x_B <= x(x'length-1 downto X_FRAC_LENGTH);
    w_x_A <= x(X_FRAC_LENGTH-1 downto 0);
    
    process (clk)
    begin
        if rising_edge(clk) then
            -- Fetch Operands
            r_i_x <= signed('0' & std_logic_vector(w_x_A));
            r_i_coeffs <= TRIG_COEFF_TABLE(to_integer(unsigned(w_x_B)));
            
            -- Load operands
            r_0_x(r_0_x'length - 1 downto r_i_x'length) <= (others => '0');
            r_0_x(r_i_x'range) <= r_i_x;
            
            r_0_c_0_sin <= signed(r_i_coeffs(POLY_WIDTHS(2) - 1 downto POLY_WIDTHS(1)));
            r_0_c_1_sin <= signed(r_i_coeffs(POLY_WIDTHS(3) - 1 downto POLY_WIDTHS(2)));
            
            r_0_c_0_cos <= signed(r_i_coeffs(POLY_WIDTHS(0) - 1 downto 0));
            r_0_c_1_cos <= signed(r_i_coeffs(POLY_WIDTHS(1) - 1 downto POLY_WIDTHS(0)));
            
            
            -- DSP Input Buffer Stage
            -- r_d_x <= r_0_x;
            -- r_d_coeffs <= r_0_coeffs;
            -- r_d_c_1 <= r_0_c_1;
            
            
            -- eta_2 = C_2 * x
            r_1_y_sin <= r_0_c_1_sin * r_0_x;
            r_1_y_cos <= r_0_c_1_cos * r_0_x;
            
            r_1_c_0_sin(r_1_c_0_sin'length-COEFF_WIDTHS(0)-1 downto 0) <= (others => '0');
            r_1_c_0_sin(r_1_c_0_sin'length-1 downto r_1_c_0_sin'length-COEFF_WIDTHS(0)) <= r_0_c_0_sin;
            
            r_1_c_0_cos(r_1_c_0_cos'length-COEFF_WIDTHS(0)-1 downto 0) <= (others => '0');
            r_1_c_0_cos(r_1_c_0_cos'length-1 downto r_1_c_0_cos'length-COEFF_WIDTHS(0)) <= r_0_c_0_cos;
            
            
            -- eta_1 = eta_2 + C_1
            r_2_y_sin <= r_1_c_0_sin + r_1_y_sin;
            r_2_y_cos <= r_1_c_0_cos + r_1_y_cos;
        end if;
    end process;
    
    y_sin(y_sin'length - 1 downto 0) <= r_2_y_sin(r_2_y_sin'length - 1 downto r_2_y_sin'length - y_sin'length);
    y_cos(y_cos'length - 1 downto 0) <= r_2_y_cos(r_2_y_cos'length - 1 downto r_2_y_cos'length - y_cos'length);

end beh;
