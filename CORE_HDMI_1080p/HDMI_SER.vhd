library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library UNISIM;
use UNISIM.VComponents.all;

-- Se realiza la serialización del dato codificado T.M.D.S. de 10 bits para transmisión diferencial.

entity serializador_tmds is
  port(
    clk             : in std_logic;                         -- Pixel_clock
    ddr_clk         : in std_logic;                         -- DDR bit clock (pixel_clock*5)
    reset           : in std_logic;                         -- Reset síncrono con pixel clock, activo nivel alto
    dato            : in std_logic_vector(9 downto 0);      -- Dato de salida del codificador T.M.D.S.
    tmds_out        : out std_logic_vector(1 downto 0));    -- Salida diferencial del serializador
end serializador_tmds;

architecture arq_serializador_tmds of serializador_tmds is
  signal shiftout1, shiftout2   : std_logic;                -- Expansión maestro-esclavo OSERDESE2
  signal dato_se                : std_logic;                -- Dato serializado
  signal reset_sincrono         : std_logic;
                  
begin
------------------------------------------------------------------------------------------------------------------------
    process(clk)                                            -- Sincronización de reset
        begin
        if (clk'event and clk = '1') then
            reset_sincrono <= reset;
        end if;
    end process;
------------------------------------------------------------------------------------------------------------------------    
  Maestro : OSERDESE2                                       -- Conversor paralelo a serie de 10 bits, es necesaria una 
    generic map(                                            -- configuración maestro-esclavo por entrada mayor de 8 bits
      DATA_RATE_OQ => "DDR",
      DATA_RATE_TQ => "SDR",
      DATA_WIDTH => 10,
      SERDES_MODE => "MASTER",
      TRISTATE_WIDTH => 1,
      TBYTE_CTL => "FALSE",
      TBYTE_SRC => "FALSE")
    port map(
      CLK => ddr_clk,
      CLKDIV => clk,
      D1 => dato(0),
      D2 => dato(1),
      D3 => dato(2),
      D4 => dato(3),
      D5 => dato(4),
      D6 => dato(5),
      D7 => dato(6),
      D8 => dato(7),
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TCE => '1',
      OCE => '1',
      TBYTEIN => '0',
      RST => reset_sincrono,
      SHIFTIN1 => shiftout1,
      SHIFTIN2 => shiftout2,
      OQ => dato_se,
      OFB => open,
      TQ => open,
      TFB => open,
      TBYTEOUT => open,
      SHIFTOUT1 => open,
      SHIFTOUT2 => open);     
  Esclavo : OSERDESE2
    generic map(
      DATA_RATE_OQ => "DDR",
      DATA_RATE_TQ => "SDR",
      DATA_WIDTH => 10,
      SERDES_MODE => "SLAVE",
      TRISTATE_WIDTH => 1,
      TBYTE_CTL => "FALSE",
      TBYTE_SRC => "FALSE")
    port map(
      CLK => ddr_clk,
      CLKDIV => clk,
      D1 => '0',
      D2 => '0',
      D3 => dato(8),
      D4 => dato(9),
      D5 => '0',
      D6 => '0',
      D7 => '0',
      D8 => '0',
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TCE => '1',
      OCE => '1',
      TBYTEIN => '0',
      RST => reset_sincrono,
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      OQ => open,
      OFB => open,
      TQ => open,
      TFB => open,
      TBYTEOUT => open,
      SHIFTOUT1 => shiftout1,
      SHIFTOUT2 => shiftout2);
------------------------------------------------------------------------------------------------------------------------
  Salida_diferencial : OBUFDS                               -- Buffer de salida diferencial
    generic map (
      IOSTANDARD => "DEFAULT",
      SLEW => "FAST")
    port map (
      I => dato_se,
      O => tmds_out(1),
      OB => tmds_out(0));
------------------------------------------------------------------------------------------------------------------------      
end arq_serializador_tmds;
