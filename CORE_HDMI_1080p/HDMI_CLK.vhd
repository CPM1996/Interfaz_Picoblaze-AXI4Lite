library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library UNISIM;
use UNISIM.VComponents.all;

-- Se realiza la generación de la señal de reloj para transmisión diferencial

entity generador_clk_tmds is
  port(
    clk         : in std_logic;                         -- Pixel clock
    tmds_clk    : out std_logic_vector(1 downto 0));    -- CLK diferencial de salida (1-->P, 0-->N)
    
end generador_clk_tmds;

architecture arq_generador_clk_tmds of generador_clk_tmds is
    signal clk_interno  :   std_logic;
    
begin
-------------------------------------------------------------------------------------------------------------------
  Generador_clk_interno    : ODDR
    generic map (
      DDR_CLK_EDGE => "OPPOSITE_EDGE",
      INIT => '0',
      SRTYPE => "SYNC")
    port map (
      Q => clk_interno,
      C => clk,
      CE => '1',
      D1 => '1',
      D2 => '0',
      R => '0',
      S => '0');   
-------------------------------------------------------------------------------------------------------------------
  Salida_diferencial : OBUFDS                               -- Buffer de salida diferencial
    generic map (
      IOSTANDARD => "DEFAULT",
      SLEW => "FAST")
    port map (
      I => clk_interno,
      O => tmds_clk(1),
      OB => tmds_clk(0));
-------------------------------------------------------------------------------------------------------------------
end arq_generador_clk_tmds;
