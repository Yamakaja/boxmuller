LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.output_remapper_fixpt_pkg.ALL;

ENTITY output_remapper_fixpt IS
  PORT( clk                               :   IN    std_logic;
        rstn                              :   IN    std_logic;
        en                                :   IN    std_logic;
        x_in                              :   IN    signed(15 DOWNTO 0);  -- sfix16_En11
        factor                            :   IN    unsigned(15 DOWNTO 0);  -- ufix16_En8
        offset                            :   IN    signed(7 DOWNTO 0);  -- sfix8_En2
        ce_out                            :   OUT   std_logic;
        y_out                             :   OUT   signed(7 DOWNTO 0)  -- sfix8_En2
        );
END output_remapper_fixpt;


ARCHITECTURE rtl OF output_remapper_fixpt IS

  -- Signals
  SIGNAL enb                              : std_logic;
  SIGNAL r_1_reg_reg                      : vector_of_signed16(0 TO 1);  -- sfix16 [2]
  SIGNAL r_1                              : signed(15 DOWNTO 0);  -- sfix16_En11
  SIGNAL factor_1                         : unsigned(15 DOWNTO 0);  -- ufix16_En8
  SIGNAL tmp                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL p22tmp_cast                      : signed(16 DOWNTO 0);  -- sfix17_En8
  SIGNAL p22tmp_mul_temp                  : signed(32 DOWNTO 0);  -- sfix33_En19
  SIGNAL p22tmp_cast_1                    : signed(31 DOWNTO 0);  -- sfix32_En19
  SIGNAL r_2                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL offset_1                         : signed(7 DOWNTO 0);  -- sfix8_En2
  SIGNAL tmp_1                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL p19tmp_add_cast                  : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL p19tmp_add_cast_1                : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL p19tmp_add_temp                  : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL r_3                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_2                            : std_logic;
  SIGNAL ex                               : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL ex_1                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_3                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_4                            : std_logic;
  SIGNAL ex_2                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL ex_3                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_5                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_6                            : signed(5 DOWNTO 0);  -- sfix6_En2
  SIGNAL r_5_reg_reg                      : vector_of_signed6(0 TO 1);  -- sfix6 [2]
  SIGNAL r_5                              : signed(5 DOWNTO 0);  -- sfix6_En2
  SIGNAL y_out_1                          : signed(7 DOWNTO 0);  -- sfix8_En2

BEGIN
  enb <= en;

  r_1_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      r_1_reg_reg <= (OTHERS => to_signed(16#0000#, 16));
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        r_1_reg_reg(0) <= x_in;
        r_1_reg_reg(1) <= r_1_reg_reg(0);
      END IF;
    END IF;
  END PROCESS r_1_reg_process;

  r_1 <= r_1_reg_reg(1);

  factor_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      factor_1 <= to_unsigned(16#0000#, 16);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        factor_1 <= factor;
      END IF;
    END IF;
  END PROCESS factor_reg_process;


  p22tmp_cast <= signed(resize(factor_1, 17));
  p22tmp_mul_temp <= r_1 * p22tmp_cast;
  
  p22tmp_cast_1 <= X"7FFFFFFF" WHEN (p22tmp_mul_temp(32) = '0') AND (p22tmp_mul_temp(31) /= '0') ELSE
      X"80000000" WHEN (p22tmp_mul_temp(32) = '1') AND (p22tmp_mul_temp(31) /= '1') ELSE
      p22tmp_mul_temp(31 DOWNTO 0);
  tmp <= (resize(p22tmp_cast_1(31 DOWNTO 17), 16)) + ('0' & p22tmp_cast_1(16));

  r_2_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      r_2 <= to_signed(16#0000#, 16);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        r_2 <= tmp;
      END IF;
    END IF;
  END PROCESS r_2_reg_process;


  offset_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      offset_1 <= to_signed(16#00#, 8);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        offset_1 <= offset;
      END IF;
    END IF;
  END PROCESS offset_reg_process;


  p19tmp_add_cast <= resize(r_2, 17);
  p19tmp_add_cast_1 <= resize(offset_1, 17);
  p19tmp_add_temp <= p19tmp_add_cast + p19tmp_add_cast_1;
  
  tmp_1 <= X"7FFF" WHEN (p19tmp_add_temp(16) = '0') AND (p19tmp_add_temp(15) /= '0') ELSE
      X"8000" WHEN (p19tmp_add_temp(16) = '1') AND (p19tmp_add_temp(15) /= '1') ELSE
      p19tmp_add_temp(15 DOWNTO 0);

  -- HDL code generation from MATLAB function: output_remapper_fixpt
  -- 
  -- HDL code generation from MATLAB function: output_remapper_fixpt_falseregionp10
  r_3_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      r_3 <= to_signed(16#0000#, 16);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        r_3 <= tmp_1;
      END IF;
    END IF;
  END PROCESS r_3_reg_process;


  
  tmp_2 <= '1' WHEN r_3 < to_signed(-16#001E#, 16) ELSE
      '0';

  -- HDL code generation from MATLAB function: output_remapper_fixpt_trueregionp10
  ex <= to_signed(-16#001E#, 16);

  delayMatch_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      ex_1 <= to_signed(16#0000#, 16);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        ex_1 <= ex;
      END IF;
    END IF;
  END PROCESS delayMatch_process;


  -- HDL code generation from MATLAB function: output_remapper_fixpt_falseregionp5
  
  tmp_3 <= r_3 WHEN tmp_2 = '0' ELSE
      ex_1;

  
  tmp_4 <= '1' WHEN tmp_3 > to_signed(16#001E#, 16) ELSE
      '0';

  -- HDL code generation from MATLAB function: output_remapper_fixpt_trueregionp5
  ex_2 <= to_signed(16#001E#, 16);

  delayMatch_1_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      ex_3 <= to_signed(16#0000#, 16);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        ex_3 <= ex_2;
      END IF;
    END IF;
  END PROCESS delayMatch_1_process;


  
  tmp_5 <= tmp_3 WHEN tmp_4 = '0' ELSE
      ex_3;

  
  tmp_6 <= "011111" WHEN (tmp_5(15) = '0') AND (tmp_5(14 DOWNTO 5) /= "0000000000") ELSE
      "100000" WHEN (tmp_5(15) = '1') AND (tmp_5(14 DOWNTO 5) /= "1111111111") ELSE
      tmp_5(5 DOWNTO 0);

  r_5_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      r_5_reg_reg <= (OTHERS => to_signed(16#00#, 6));
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        r_5_reg_reg(0) <= tmp_6;
        r_5_reg_reg(1) <= r_5_reg_reg(0);
      END IF;
    END IF;
  END PROCESS r_5_reg_process;

  r_5 <= r_5_reg_reg(1);

  y_out_1 <= resize(r_5, 8);

  y_out_reg_process : PROCESS (clk, rstn)
  BEGIN
    IF rstn = '0' THEN
      y_out <= to_signed(16#00#, 8);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        y_out <= y_out_1;
      END IF;
    END IF;
  END PROCESS y_out_reg_process;


  ce_out <= en;

END rtl;

