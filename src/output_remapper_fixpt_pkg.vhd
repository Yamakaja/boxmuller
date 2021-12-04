-- Generated from MATLAB

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

PACKAGE output_remapper_fixpt_pkg IS
  TYPE vector_of_signed16 IS ARRAY (NATURAL RANGE <>) OF signed(15 DOWNTO 0);
  TYPE vector_of_signed6 IS ARRAY (NATURAL RANGE <>) OF signed(5 DOWNTO 0);
END output_remapper_fixpt_pkg;

