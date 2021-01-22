library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity reductor_transiciones is
  port(  
    clk             : in  std_logic;                               -- Pixel clock
    reset           : in  std_logic;                               -- Reset síncrono con pixel clock, activo nivel alto
    dato            : in  std_logic_vector(7 downto 0):=x"00";     -- Dato de entrada
    q_m_reg         : out std_logic_vector(8 downto 0));           -- Dato de salida codificado
     
end reductor_transiciones;

architecture behavioral of reductor_transiciones is
  
  signal q_m_0,q_m_0_n, q_m        : std_logic_vector(8 downto 0);
  signal N1_dato                   : unsigned(3 downto 0);
  
----Función suma---------------------------------------------------------------------------------------
  function sum_bits(u : std_logic_vector) return unsigned is
     variable sum : unsigned(3 downto 0);
	  begin
        assert u'length < 16 report "sum_bits error";
        sum := to_unsigned(0,4);
		  for i in u'range loop
           sum := sum + unsigned(u(i downto i));
		  end loop;
		  return sum;
	end function;
-----------------------------------------------------------------------------------------
begin
  --Lógica combinacional de codificación-----------------------------------------------------
  q_m_0 <= '1' & (q_m(6 downto 0) xor dato(7 downto 1)) & dato(0);
  q_m_0_n <= not q_m_0(8 downto 1) & dato(0);
  
  N1_dato <=sum_bits(dato);
  q_m <= q_m_0_n when N1_dato > 4 or (N1_dato = 4 and dato(0) = '0') else q_m_0;
  
  --Registro de salida con reset---------------------------------------------------------------
  process(clk) begin
    if rising_edge(clk) then
      if reset = '1' then
        q_m_reg <= "000000000";
      else
        q_m_reg <= q_m;
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------
end;