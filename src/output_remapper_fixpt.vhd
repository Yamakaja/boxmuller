-- Generated from MATLAB

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
  SIGNAL multiplier_cast                  : signed(16 DOWNTO 0);  -- sfix17_En8
  SIGNAL multiplier_mul_temp              : signed(32 DOWNTO 0);  -- sfix33_En19
  SIGNAL tmp                              : signed(31 DOWNTO 0);  -- sfix32_En19
  SIGNAL tmp_1                            : signed(31 DOWNTO 0);  -- sfix32_En19
  SIGNAL tmp_2                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL r_2                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_3                            : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL offset_1                         : signed(7 DOWNTO 0);  -- sfix8_En2
  SIGNAL tmp_4                            : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL tmp_5                            : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL adder_add_cast                   : signed(17 DOWNTO 0);  -- sfix18_En2
  SIGNAL adder_add_cast_1                 : signed(17 DOWNTO 0);  -- sfix18_En2
  SIGNAL adder_add_temp                   : signed(17 DOWNTO 0);  -- sfix18_En2
  SIGNAL tmp_6                            : signed(16 DOWNTO 0);  -- sfix17_En2
  SIGNAL tmp_7                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL r_3                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_8                            : std_logic;
  SIGNAL ex                               : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL delayMatch_reg                   : vector_of_signed16(0 TO 1);  -- sfix16 [2]
  SIGNAL ex_1                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_9                            : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL r_4                              : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_10                           : std_logic;
  SIGNAL ex_2                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL delayMatch_reg_1                 : vector_of_signed16(0 TO 1);  -- sfix16 [2]
  SIGNAL ex_3                             : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_11                           : signed(15 DOWNTO 0);  -- sfix16_En2
  SIGNAL tmp_12                           : signed(5 DOWNTO 0);  -- sfix6_En2
  SIGNAL r_5                              : signed(5 DOWNTO 0);  -- sfix6_En2
  SIGNAL tmp_13                           : signed(7 DOWNTO 0);  -- sfix8_En2

BEGIN
  enb <= en;

  r_1_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        r_1_reg_reg <= (OTHERS => to_signed(16#0000#, 16));
      ELSIF enb = '1' THEN
        r_1_reg_reg(0) <= x_in;
        r_1_reg_reg(1) <= r_1_reg_reg(0);
      END IF;
    END IF;
  END PROCESS r_1_reg_process;

  r_1 <= r_1_reg_reg(1);

  factor_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        factor_1 <= to_unsigned(16#0000#, 16);
      ELSIF enb = '1' THEN
        factor_1 <= factor;
      END IF;
    END IF;
  END PROCESS factor_reg_process;


  multiplier_cast <= signed(resize(factor_1, 17));
  multiplier_mul_temp <= r_1 * multiplier_cast;
  tmp <= multiplier_mul_temp(31 DOWNTO 0);

  buff_out_pipe_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        tmp_1 <= to_signed(0, 32);
      ELSIF enb = '1' THEN
        tmp_1 <= tmp;
      END IF;
    END IF;
  END PROCESS buff_out_pipe_process;


  tmp_2 <= (resize(tmp_1(31 DOWNTO 17), 16)) + ('0' & tmp_1(16));

  r_2_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        r_2 <= to_signed(16#0000#, 16);
      ELSIF enb = '1' THEN
        r_2 <= tmp_2;
      END IF;
    END IF;
  END PROCESS r_2_reg_process;


  tmp_3 <= resize(r_2, 17);

  offset_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        offset_1 <= to_signed(16#00#, 8);
      ELSIF enb = '1' THEN
        offset_1 <= offset;
      END IF;
    END IF;
  END PROCESS offset_reg_process;


  tmp_4 <= resize(offset_1, 17);

  delayMatch_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        tmp_5 <= to_signed(16#00000#, 17);
      ELSIF enb = '1' THEN
        tmp_5 <= tmp_4;
      END IF;
    END IF;
  END PROCESS delayMatch_process;


  adder_add_cast <= resize(tmp_3, 18);
  adder_add_cast_1 <= resize(tmp_5, 18);
  adder_add_temp <= adder_add_cast + adder_add_cast_1;
  
  tmp_6 <= "01111111111111111" WHEN (adder_add_temp(17) = '0') AND (adder_add_temp(16) /= '0') ELSE
      "10000000000000000" WHEN (adder_add_temp(17) = '1') AND (adder_add_temp(16) /= '1') ELSE
      adder_add_temp(16 DOWNTO 0);

  
  tmp_7 <= X"7FFF" WHEN (tmp_6(16) = '0') AND (tmp_6(15) /= '0') ELSE
      X"8000" WHEN (tmp_6(16) = '1') AND (tmp_6(15) /= '1') ELSE
      tmp_6(15 DOWNTO 0);

  -- HDL code generation from MATLAB function: output_remapper_fixpt
  -- 
  -- HDL code generation from MATLAB function: output_remapper_fixpt_falseregionp24
  r_3_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        r_3 <= to_signed(16#0000#, 16);
      ELSIF enb = '1' THEN
        r_3 <= tmp_7;
      END IF;
    END IF;
  END PROCESS r_3_reg_process;


  
  tmp_8 <= '1' WHEN r_3 < to_signed(-16#001E#, 16) ELSE
      '0';

  -- HDL code generation from MATLAB function: output_remapper_fixpt_trueregionp24
  ex <= to_signed(-16#001E#, 16);

  delayMatch_1_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        delayMatch_reg <= (OTHERS => to_signed(16#0000#, 16));
      ELSIF enb = '1' THEN
        delayMatch_reg(0) <= ex;
        delayMatch_reg(1) <= delayMatch_reg(0);
      END IF;
    END IF;
  END PROCESS delayMatch_1_process;

  ex_1 <= delayMatch_reg(1);

  
  tmp_9 <= r_3 WHEN tmp_8 = '0' ELSE
      ex_1;

  -- HDL code generation from MATLAB function: output_remapper_fixpt_falseregionp29
  r_4_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        r_4 <= to_signed(16#0000#, 16);
      ELSIF enb = '1' THEN
        r_4 <= tmp_9;
      END IF;
    END IF;
  END PROCESS r_4_reg_process;


  
  tmp_10 <= '1' WHEN r_4 > to_signed(16#001E#, 16) ELSE
      '0';

  -- HDL code generation from MATLAB function: output_remapper_fixpt_trueregionp29
  ex_2 <= to_signed(16#001E#, 16);

  delayMatch_2_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        delayMatch_reg_1 <= (OTHERS => to_signed(16#0000#, 16));
      ELSIF enb = '1' THEN
        delayMatch_reg_1(0) <= ex_2;
        delayMatch_reg_1(1) <= delayMatch_reg_1(0);
      END IF;
    END IF;
  END PROCESS delayMatch_2_process;

  ex_3 <= delayMatch_reg_1(1);

  
  tmp_11 <= r_4 WHEN tmp_10 = '0' ELSE
      ex_3;

  
  tmp_12 <= "011111" WHEN (tmp_11(15) = '0') AND (tmp_11(14 DOWNTO 5) /= "0000000000") ELSE
      "100000" WHEN (tmp_11(15) = '1') AND (tmp_11(14 DOWNTO 5) /= "1111111111") ELSE
      tmp_11(5 DOWNTO 0);

  r_5_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        r_5 <= to_signed(16#00#, 6);
      ELSIF enb = '1' THEN
        r_5 <= tmp_12;
      END IF;
    END IF;
  END PROCESS r_5_reg_process;


  tmp_13 <= resize(r_5, 8);

  y_out_reg_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rstn = '0' THEN
        y_out <= to_signed(16#00#, 8);
      ELSIF enb = '1' THEN
        y_out <= tmp_13;
      END IF;
    END IF;
  END PROCESS y_out_reg_process;


  ce_out <= en;

END rtl;

