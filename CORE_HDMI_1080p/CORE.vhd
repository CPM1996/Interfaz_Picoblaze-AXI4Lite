library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- CORE para transmisión de video H.D.M.I.

entity CORE_HDMI is
  port(
    pixel_clock     : in std_logic;                         -- Pixel clock
    ddr_bit_clock   : in std_logic;                         -- DDR bit clock (pixel_clock*5)
    reset           : in std_logic;                         -- Reset síncrono con pixel clock, activo nivel alto
    den             : in std_logic;                         -- Display enable, activo nivel alto
    hsync           : in std_logic;                         -- Sincronización horizontal de video
    vsync           : in std_logic;                         -- Sincronización vertical de video
    pixel_data      : in std_logic_vector(23 downto 0);     -- Dato de entrada RGB de 24 bits
    tmds_clk        : out std_logic_vector(1 downto 0);     -- CLK diferencial de salida
    tmds_d0         : out std_logic_vector(1 downto 0);     -- Salidas diferenciales codificadas T.M.D.S y serializadas
    tmds_d1         : out std_logic_vector(1 downto 0);
    tmds_d2         : out std_logic_vector(1 downto 0));
end CORE_HDMI;

architecture arq_CORE_HDMI of CORE_HDMI is
    signal tmds_cod0            : std_logic_vector(9 downto 0) :="0000000000";      -- Dato RGB codificado y separado en componentes 
    signal tmds_cod1            : std_logic_vector(9 downto 0) :="0000000000";
    signal tmds_cod2            : std_logic_vector(9 downto 0) :="0000000000"; 
    
begin

-----------------------------------------------------------------------------------------------------------------------------
        Codificador_R : entity work.codificador_tmds                -- Codificación T.M.D.S. Red
            port map(
                clk => pixel_clock,
                reset => reset,
                den => den,
                dato => pixel_data(23 downto 16),
                C0 => '0',
                C1 => '0',
                TMDS_Channel => 2, 
                q_out => tmds_cod2);
                
        Serializador_R : entity work.serializador_tmds              -- Serialización Red
            port map(
                clk => pixel_clock,
                ddr_clk => ddr_bit_clock,
                reset => reset,    
                dato => tmds_cod2,
                tmds_out => tmds_d2);
-----------------------------------------------------------------------------------------------------------------------------
        Codificador_G : entity work.codificador_tmds                -- Codificación T.M.D.S. Green
            port map(
                clk => pixel_clock,
                reset => reset,
                den => den,
                dato => pixel_data(15 downto 8), 
                C0 => '1',
                C1 => '0',
                TMDS_Channel => 1, 
                q_out => tmds_cod1);
                
        Serializador_G : entity work.serializador_tmds              -- Serialización Green
            port map(
                clk => pixel_clock,
                ddr_clk => ddr_bit_clock,
                reset => reset,    
                dato => tmds_cod1,
                tmds_out => tmds_d1);
-----------------------------------------------------------------------------------------------------------------------------
        Codificador_B : entity work.codificador_tmds                -- Codificación T.M.D.S. Blue
            port map(
                clk => pixel_clock,
                reset => reset,
                den => den,
                dato => pixel_data(7 downto 0), 
                C0 => hsync,
                C1 => vsync,
                TMDS_Channel => 0,
                q_out => tmds_cod0);
                                
        Serializador_B : entity work.serializador_tmds              -- Serialización Blue
            port map(
                clk => pixel_clock,
                ddr_clk => ddr_bit_clock,
                reset => reset,    
                dato => tmds_cod0,
                tmds_out => tmds_d0);
-----------------------------------------------------------------------------------------------------------------------------
        TMDS_CLK_generador : entity work.generador_clk_tmds         -- Generación de T.M.D.S. CLK
            port map( 
                clk => pixel_clock,
                tmds_clk => tmds_clk);
-----------------------------------------------------------------------------------------------------------------------------
end arq_CORE_HDMI;