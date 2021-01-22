library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;

-- Se realiza la codificación de un dato de entrada de 8 bits según algorítmo de
-- codificación T.M.D.S. obteniendo un dato de salida de 10 bits

entity codificador_tmds is
  port(  
    clk             : in  std_logic;                        -- Pixel clock
    den             : in  std_logic;                        -- Display enable, activo nivel alto
    reset           : in  std_logic;                        -- Reset síncrono con pixel clock, activo nivel alto
    C0              : in  std_logic;                        -- Señal de control C0
    C1              : in  std_logic;                        -- Señal de control C1
    dato            : in  std_logic_vector(7 downto 0);     -- Dato de entrada
    TMDS_Channel    : in  natural range 0 to 2;             -- Canal en codificación
    q_out           : out std_logic_vector(9 downto 0));    -- Dato de salida codificado
     
end codificador_tmds;

architecture arq_codificador_tmds of codificador_tmds is
  signal q_m                                        : std_logic_vector(8 downto 0) :="000000000";     -- Dato interno
  signal control                                    : std_logic_vector(1 downto 0) :="00";     -- Concatenación C1 C0
  signal cnt                                        : integer range -16 to 15 :=0;      -- Registro para seguimiento de la disparidad en el flujo de datos
  signal N1_dato                                    : unsigned (3 downto 0);
  signal den_reg                                    : std_logic;          
    
begin
  
etapa_1: entity work.reductor_transiciones(behavioral)
    port map(
       clk => clk,
       reset => reset,
       dato => dato,
       q_m_reg => q_m
    );
        
  process(clk)                                                              -- Diseño en un sólo proceso
    variable N1_q_m         : integer range 0 to 8 :=0;         -- Número de '1's en dato interno
    variable N0_q_m         : integer range 0 to 8 :=0;         -- Número de '0's en dato interno
        
  begin
                                            
    if(clk'event and clk = '1') then                                        -- Sincronismo y testeo reset                            
        if reset = '1' then 
            N1_dato<=x"0";
            N1_dato<="0000";        
            N1_q_m := 0;
            N0_q_m := 0;       
            cnt <= 0;
            q_out <= "0000000000";  
        else
----------------------------------------------------------------------------------------------------------------------------
            den_reg <=den; --Retardo de un ciclo de la señal den
            
            if(den_reg = '1') then                                              -- VIDEO ENCODING PERIOD
---------------------------------------------------------------------------------------------------------------------------- 
                N1_q_m := 0;                                                -- Cálculo del número de '1's y '0's de
                N0_q_m := 0;                                                -- dato interno
                for i in 0 to 7 loop                                        
                    if(q_m(i) = '1') then
                        N1_q_m := N1_q_m + 1;
                    end if;
                end loop;
                N0_q_m := 8 - N1_q_m;
----------------------------------------------------------------------------------------------------------------------------  
                if(cnt = 0 or N1_q_m = N0_q_m) then                         -- Asignación de valores a dato de salida
                    q_out(9) <= not q_m(8);
                    q_out(8) <= q_m(8); 
                    if(q_m(8) = '0') then
                        q_out(7 downto 0) <= not q_m(7 downto 0);
                        cnt <= cnt + (N0_q_m - N1_q_m);
                    else
                        q_out(7 downto 0) <= q_m(7 downto 0);
                        cnt <= cnt + (N1_q_m - N0_q_m);
                    end if;
                else
                    if((cnt > 0 and N1_q_m > N0_q_m) or (cnt < 0 and N0_q_m > N1_q_m)) then
                        q_out(9) <= '1';
                        q_out(8) <= q_m(8);
                        q_out(7 downto 0) <= not q_m(7 downto 0);
                        if(q_m(8) = '0') then
                            cnt <= cnt + (N0_q_m - N1_q_m);
                        else
                            cnt <= cnt + 2 + (N0_q_m - N1_q_m);
                        end if;
                    else         
                        q_out(9) <= '0';
                        q_out(8 downto 0) <= q_m(8 downto 0);
                        if(q_m(8) = '0') then
                            cnt <= cnt - 2 + (N1_q_m - N0_q_m);
                        else
                            cnt <= cnt + (N1_q_m - N0_q_m);
                        end if;
                    end if;
                end if;
----------------------------------------------------------------------------------------------------------------------------
            else                                                            -- BLANKING PERIOD
                cnt <= 0;
                control <= C1 & C0;                                                                                
                case control is                                         -- Señales de control - Pre-Video Data  
                    when "00" => q_out <= "1101010100";
                    when "01" => q_out <= "0010101011";
                    when "10" => q_out <= "0101010100";
                    when "11" => q_out <= "1010101011";
                    when others => NULL;
               end case;                                                
            end if;
        end if;
    end if;
  end process;
end arq_codificador_tmds;