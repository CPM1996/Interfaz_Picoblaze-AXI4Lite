-------------------------Interfaz PicoBlaze - AXI Lite----------------------------------------------------------------------------

--    Autor: Carlos Pérez Muñoz

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PB_AXIL_32 is
  generic(
    port_pos      : std_logic_vector:=x"00"                             --Puerto de referencia de la interfaz
);
  port(
    --Entradas comunes------------------------------------------------------------------------------------------------------------
    CLK           : in std_logic;                                       --Entrada de reloj
    RSTn          : in std_logic;                                       --Reset activo a nivel bajo
    --Interfaz PicoBlaze----------------------------------------------------------------------------------------------------------
    in_port       : out std_logic_vector(7 downto 0):=x"00";            --Bus de datos de entrada de PicoBlaze
    out_port      : in std_logic_vector(7 downto 0);                    --Bus de datos de salida de Picoblaze
    port_id       : in std_logic_vector(7 downto 0);                    --Bus de direcciones de E/S de Picoblaze
    read_strobe   : in std_logic;                                       --Habilitación de lectura de puerto
    write_strobe  : in std_logic;                                       --Habilitación de escritura de variable en puerto 
    k_write_strobe: in std_logic;                                       --Habilitación de escritura de constante en puerto
    capturing     : out std_logic:='0';                                 --No se debería acceder a otros periféricos mientras esté activo.
    
    --Interfaz AXI Lite-----------------------------------------------------------------------------------------------------------
    ----Bus de direcciones de escritura-------------------------------------------------------------------------------------------
    AWVALID       : out std_logic:='0';                                 --Dato de bus válido
    AWREADY       : in std_logic;                                       --Esclavo listo para recibir
    AWADDR        : out std_logic_vector(31 downto 0):=(others => '0'); --Bus de direcciones para escritura
    AWPROT        : out std_logic_vector(2 downto 0):="000";            --Nivel de acceso en la escritura
    ----Bus de datos de escritura-------------------------------------------------------------------------------------------------
    WVALID        : out std_logic:='0';
    WREADY        : in std_logic;
    WDATA         : out std_logic_vector(31 downto 0):=(others =>'0');  --Bus de datos de escritura
    WSTRB         : out std_logic_vector(3 downto 0);                   --Bytes válidos del bus de datos
    ----Bus de respuesta de escritura---------------------------------------------------------------------------------------------
    BVALID        : in std_logic;
    BREADY        : out std_logic:='0';
    BRESP         : in std_logic_vector(1 downto 0);                    --Respuesta del esclavo con el estado final de la escritura
    ----Bus de direcciones de lectura---------------------------------------------------------------------------------------------
    ARVALID       : out std_logic:='0';                            
    ARREADY       : in std_logic:='0';                             
    ARADDR        : out std_logic_vector(31 downto 0):=(others => '0'); --Bus de direcciones para lectura
    ARPROT        : out std_logic_vector(2 downto 0):="000";            --Nivel de acceso en la lectura
    ----Bus de datos de lectura---------------------------------------------------------------------------------------------------
    RVALID        : in std_logic;
    RREADY        : out std_logic:='0';
    RDATA         : in std_logic_vector(31 downto 0):=(others =>'0');
    RRESP         : in std_logic_vector(1 downto 0)
  );
end PB_AXIL_32;
  
architecture Behavioral of PB_AXIL_32 is
  type ESTADOS is (IDLE, WRITE, AWAITING_WR, READ, AWAITING_RD, PB_READING);
  --Declaración de señales-------------------------------------------------------------------------------------------------------
  signal wr_strb                  : std_logic;                   --OR de write_strobe y k_write_strobe
  signal AWVALID_i,     
  WVALID_i, ARVALID_i             : std_logic;                   
  signal RREADY_i, BREADY_i       : std_logic;
  
  signal estado                   : ESTADOS;
  signal port_id_i                : std_logic_vector(7 downto 0);
  signal byte_width               : unsigned(1 downto 0):="00";
  signal byte_read                : unsigned(2 downto 0):="000";
  signal byte_cnt                 : natural range 0 to 4;
  signal RD_reg                   : std_logic_vector(31 downto 0):=(others=>'0');
  
  --Posiciones del registro de estado---------------------------------------------------------------------------------------------
  constant R_DONE_POS             : natural:=3;
  constant R_ERROR_POS            : natural:=2;
  constant W_DONE_POS             : natural:=1;
  constant W_ERROR_POS            : natural:=0;
  
begin
  wr_strb           <= write_strobe or k_write_strobe;
  WSTRB             <= WVALID_i & WVALID_i 
                       & WVALID_i & WVALID_i;           --Uso del bus de datos completo             
  AWVALID           <= AWVALID_i;
  WVALID            <= WVALID_i;
  ARVALID           <= ARVALID_i;
  RREADY            <= RREADY_i;
  BREADY            <= BREADY_i;
  port_id_i         <= x"0" & port_id(3 downto 0) when k_write_strobe='1' else port_id; --Ignorar 4 MSB si se usa instrucción OUTPUTK
  
  process(CLK) begin
    if rising_edge(CLK) then
    if RSTn='0' then
      AWVALID_i <= '0';
      WVALID_i  <= '0';
      ARVALID_i <= '0';
      RREADY_i  <= '0';
      BREADY_i  <= '0';
      capturing <= '0';
      in_port   <= x"00";
      estado    <= IDLE;
    else
      case estado is
        when IDLE =>                                            --Estado inicial
          if wr_strb='1' and port_id_i=port_pos then            --Escritura a registro indica inicio de operación
            byte_cnt <= 0;
            byte_width <= unsigned(out_port(1 downto 0)) - 1;   --Cantitad de bytes esperada para bus de direcciones (resto a 0)
            in_port <= x"00";
            capturing <= '1';
            if out_port(7)='0' then                             --Si operación de escritura
              AWADDR <= (others=>'0');
              WDATA <= (others=>'0');
              AWPROT <= out_port(6 downto 4);
              estado <= WRITE; 
            else                                                --Si operación de lectura        
              ARADDR <= (others=>'0');
              ARPROT <= out_port(6 downto 4);
              if out_port(3 downto 2)="00" then                 --Bytes que Picoblaze espera leer incluyendo registro de estado
                byte_read<="100"; 
              else 
                byte_read<="0" & unsigned(out_port(3 downto 2)); 
              end if;
              estado <= READ;
            end if; 
          end if;
        when WRITE =>                                             --Recopilando dato y dirección a escribir
          if wr_strb='1' then
            AWADDR(byte_cnt*8+7 downto byte_cnt*8) <= port_id_i;--Captura byte a byte de menos a más significativo
            WDATA(byte_cnt*8+7 downto byte_cnt*8) <= out_port;
            if byte_cnt=byte_width then
              estado <= AWAITING_WR;
              capturing <= '0';
              AWVALID_i <= '1';                                   --Dato y dirección ya disponibles en el bus
              WVALID_i <= '1';
            else
              byte_cnt <= byte_cnt + 1;
            end if;
          end if;
        when AWAITING_WR =>                                          --Esperando a que se efectúe la escritura
          if AWVALID_i = '1' and AWREADY = '1' then AWVALID_i <= '0';--Handshake de bus de direcciones
          elsif WVALID_i = '1' and WREADY = '1'  then                --Handshake de bus de datos
            WVALID_i  <= '0';
            BREADY_i <= '1';                                         --Listo para recibir respuesta
          elsif BREADY_i = '1' and BVALID = '1' then                 --Handshake de respuesta
            BREADY_i <= '0';
            in_port(W_DONE_POS) <= '1';
            estado <= IDLE;
            if BRESP/="00" then in_port(W_ERROR_POS) <= '1'; end if; --Código distinto de "00" implica error en la escritura
          end if;
        when READ =>                                                 --Recopilando dirección para leer
          if wr_strb='1' then
            ARADDR(byte_cnt*8+7 downto byte_cnt*8) <= port_id_i;   --Recibe dirección byte a byte, de menos a más significativo
            if byte_cnt=byte_width then
              estado <= AWAITING_RD;
              capturing <= '0';
              ARVALID_i <= '1';
              RREADY_i <= '1';
            else
              byte_cnt <= byte_cnt + 1;
            end if;
          end if;
        when AWAITING_RD =>                                         --Esperando recibir dato del registro
         if ARVALID_i = '1' and ARREADY = '1' then ARVALID_i <= '0';--Handshake de bus de direcciones
         elsif RREADY_i = '1' and RVALID = '1' then                 --Handshake de bus de datos
          RREADY_i <= '0';
          RD_reg <= RDATA;
          in_port(R_DONE_POS) <= '1';
          if RRESP = "00" then                                      --Si no ha habido error, Picoblaze puede leer
             estado <= PB_READING;
             byte_cnt <= 0;
          else                                                      --Si hay error, volver a estado inicial
             in_port(R_ERROR_POS) <= '1';
             estado <= IDLE;
          end if;
         end if;
        when PB_READING =>                                          --Enviando dato leído a Picoblaze
          if read_strobe = '1' and port_id_i=port_pos then
            if byte_cnt=byte_read then
              estado <= IDLE;
            else 
              in_port <= RD_reg(7 downto 0);                        --Picoblaze lee byte a byte, empezando por el menos significativo
              RD_REG <= x"00" & RD_REG(31 downto 8);                
              byte_cnt <= byte_cnt + 1;
            end if;
          end if;
      end case;
    end if;
    end if;
  end process;
end;