----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2018 09:52:09
-- Design Name: 
-- Module Name: TOP_PB_AXIL_HDMI - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP_PB_AXIL_HDMI is
Port(
	   CLOCK_125       : in std_logic;                                  -- CLK referencia de 125MHz. Pin L16 IOSTANDARD LVCMOS33
       BTN             : in std_logic_vector(3 downto 0) := "0000";     -- Reset BTN0 Pin R18 IOSTANDARD LVCMOS33
       SW              : in std_logic_vector(3 downto 0) := "0000";
       led             : out std_logic_vector(3 downto 0):= "0000";
       UART_RX         : in std_logic:='1';
       UART_TX         : out std_logic;
       hdmi_out_en     : out std_logic :='1';                           -- Pin F17 IOSTANDARD LVCMOS33
       hdmi_hpd        : in std_logic :='1';                            -- Pin E18 IOSTANDARD LVCMOS33
       hdmi_clk        : out std_logic_vector(1 downto 0) :="00";       -- Pin H16 (P) H17 (N) IOSTANDARD TMDS_33
       hdmi_d0         : out std_logic_vector(1 downto 0) :="00";       -- Pin D19 (P) D20 (N) IOSTANDARD TMDS_33
       hdmi_d1         : out std_logic_vector(1 downto 0) :="00";       -- Pin C20 (P) B20 (N) IOSTANDARD TMDS_33
       hdmi_d2         : out std_logic_vector(1 downto 0) :="00");     -- Pin B19 (P) A20 (N) IOSTANDARD TMDS_33
end TOP_PB_AXIL_HDMI;

architecture Behavioral of TOP_PB_AXIL_HDMI is            
    
    signal MCLK, hdmi_ddr_clock         : std_logic :='0';
    signal locked, rst_i, rstn_i        : std_logic;
    
    signal sw_reg                       : std_logic_vector(3 downto 0);
    
    signal baud_x16                     : std_logic;
    signal uart_rx_port                 : std_logic_vector( 7 downto 0);
    signal uart_read, uart_write        : std_logic;
    signal uart_status                  : std_logic_vector(7 downto 0):=x"00";

    signal instruction                              : std_logic_vector(17 downto 0);
    signal address                                  : std_logic_vector(11 downto 0);
    signal bram_enable                              : std_logic;
    
    signal in_port                                  : std_logic_vector(7 downto 0);
    signal out_port, port_id                        : std_logic_vector(7 downto 0):=x"00";
    signal write_strobe, k_write_strobe, read_strobe: std_logic:='0';
    
    signal AXIL_in_port                             : std_logic_vector(7 downto 0);
    signal capturing                                : std_logic:='0';
    signal AWADDR, WDATA, ARADDR, RDATA             : std_logic_vector(31 downto 0);
    signal WSTRB                                    : std_logic_vector(3 downto 0);
    signal AWPROT, ARPROT                           : std_logic_vector(2 downto 0);
    signal RRESP,BRESP                              : std_logic_vector(1 downto 0);
    signal AWVALID, WVALID, BREADY, ARVALID, RREADY : std_logic;
    signal AWREADY, WREADY, BVALID, ARREADY, RVALID : std_logic;
    
    signal hdmi_data, RBG_data                      : std_logic_vector(23 downto 0);
    signal hdmi_hsync, hdmi_vsync, hdmi_den         : std_logic;
    
    component clk_wiz_0 is
        port(
            clk_in   : in std_logic;
            reset    : in std_logic;
            locked   : out std_logic;
            px_clk   : out std_logic;
            ddr_clk  : out std_logic);
    end component;
      
    component my_TPG is
      port (
        CLK : in STD_LOGIC;
        RSTn : in STD_LOGIC;
        Video_Output_active_video : out STD_LOGIC;
        Video_Output_data : out STD_LOGIC_VECTOR ( 23 downto 0 );
        Video_Output_field : out STD_LOGIC;
        Video_Output_hblank : out STD_LOGIC;
        Video_Output_hsync : out STD_LOGIC;
        Video_Output_vblank : out STD_LOGIC;
        Video_Output_vsync : out STD_LOGIC;
        AXI_Lite_Interface_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
        AXI_Lite_Interface_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
        AXI_Lite_Interface_awvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
        AXI_Lite_Interface_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
        AXI_Lite_Interface_wvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_wready : out STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
        AXI_Lite_Interface_bvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_bready : in STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
        AXI_Lite_Interface_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
        AXI_Lite_Interface_arvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
        AXI_Lite_Interface_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
        AXI_Lite_Interface_rvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
        AXI_Lite_Interface_rready : in STD_LOGIC_VECTOR ( 0 to 0 )     
      );
      end component my_TPG;
      
begin

sw_reg <= sw when rising_edge(MCLK);
rst_i <= not locked;
rstn_i <= locked;
hdmi_out_en <= hdmi_hpd;

uart_write <= '1' when write_strobe = '1' and port_id(1 downto 0)="01" and capturing='0' else '0';
uart_read <= '1' when read_strobe = '1' and port_id(1 downto 0)="01" else '0';
led <= out_port(3 downto 0) when rising_edge(MCLK) and port_id(1 downto 0)="11"
       and write_strobe='1' and capturing='0';

MMCM : clk_wiz_0                                                    -- Generación de señales CLK para
    port map(
        clk_in => CLOCK_125,
        reset => BTN(0),
        locked => locked,
        px_clk => MCLK,
        ddr_clk => hdmi_ddr_clock);  

Picoblaze: entity work.kcpsm6
port map(      address => address,
           instruction => instruction,
           bram_enable => bram_enable,
               port_id => port_id,
          write_strobe => write_strobe,
        k_write_strobe => k_write_strobe,
              out_port => out_port,
           read_strobe => read_strobe,
               in_port => in_port,
             interrupt => '0',
         interrupt_ack => open,
                 sleep => '0',
                 reset => rst_i,
                   clk => MCLK );
 
HDMI_program_i0: entity work.hdmi_program
generic map(
    C_family => "7S",
    C_JTAG_LOADER_ENABLE => 0
)port map(
    clk => MCLK,
    address => address,
    instruction => instruction,
    enable => bram_enable
);

with port_id(1 downto 0) select
    in_port <= axil_in_port when "00",
               uart_rx_port when "01",
               uart_status when "10",
               "0000" & sw_reg when "11",
               x"00" when others;

uart_baud_gen_x16: entity work.uart_baud_gen
    generic map(
        BAUD_RATE => 115_200,
        CLOCK_RATE => 148_500_000
        )
    port map(
        clk => MCLK,
        rst => rst_i,
        baud_x16_en => baud_x16
    );

uart_rx_module: entity work.uart_rx6 
    port map(
        serial_in => uart_rx,
        en_16_x_baud => baud_x16,
        buffer_read => uart_read,
        data_out => uart_rx_port,
        buffer_reset => rst_i,
        buffer_data_present => uart_status(3),
        buffer_half_full => uart_status(4),
        buffer_full => uart_status(5),
        clk => MCLK
    );
   
uart_tx_module: entity work.uart_tx6
    port map(
        data_in => out_port,
        en_16_x_baud => baud_x16,
        buffer_write => uart_write,
        serial_out => uart_tx,
        buffer_reset => rst_i,
        buffer_data_present => uart_status(0),
        buffer_half_full => uart_status(1),
        buffer_full => uart_status(2),
        clk => MCLK
    );

my_interf: entity work.PB_AXIL_32 port map(
    CLK => MCLK,
    RSTn => rstn_i,
    
    in_port => axil_in_port,
    out_port => out_port,
    port_id => port_id,
    write_strobe => write_strobe,
    k_write_strobe => k_write_strobe,
    read_strobe => read_strobe,
    capturing => capturing,
    
    AWADDR => AWADDR,
    AWVALID => AWVALID,
    AWREADY => AWREADY,
    AWPROT => AWPROT,
    
    WDATA => WDATA,
    WSTRB => WSTRB,
    WVALID => WVALID,
    WREADY => WREADY,
    
    BRESP => BRESP,
    BVALID => BVALID,
    BREADY => BREADY,
    
    ARADDR => ARADDR,
    ARVALID => ARVALID,
    ARREADY => ARREADY,
    ARPROT => ARPROT,
    
    RDATA => RDATA,
    RVALID => RVALID,
    RREADY => RREADY,
    RRESP => RRESP
);

my_TPG_i0: component my_TPG
     port map (
      CLK => MCLK,
      RSTn =>rstn_i,
      AXI_Lite_Interface_araddr => ARADDR,
      AXI_Lite_Interface_arprot => ARPROT,
      AXI_Lite_Interface_arready(0) => ARREADY,
      AXI_Lite_Interface_arvalid(0) => ARVALID,
      AXI_Lite_Interface_awaddr => AWADDR,
      AXI_Lite_Interface_awprot => AWPROT,
      AXI_Lite_Interface_awready(0) => AWREADY,
      AXI_Lite_Interface_awvalid(0) => AWVALID,
      AXI_Lite_Interface_bready(0) => BREADY,
      AXI_Lite_Interface_bresp => BRESP,
      AXI_Lite_Interface_bvalid(0) => BVALID,
      AXI_Lite_Interface_rdata => RDATA,
      AXI_Lite_Interface_rready(0) => RREADY,
      AXI_Lite_Interface_rresp => RRESP,
      AXI_Lite_Interface_rvalid(0) => RVALID,
      AXI_Lite_Interface_wdata => WDATA,
      AXI_Lite_Interface_wready(0) => WREADY,
      AXI_Lite_Interface_wstrb => WSTRB,
      AXI_Lite_Interface_wvalid(0) => WVALID,
      Video_Output_active_video => HDMI_den,
      Video_Output_data => RBG_data,
      Video_Output_field => open,
      Video_Output_hblank => open,
      Video_Output_hsync => HDMI_hsync,
      Video_Output_vblank => open,
      Video_Output_vsync => HDMI_vsync
    );
    
HDMI_data <= RBG_data(23 downto 16) & RBG_data(7 downto 0) & RBG_data(15 downto 8);

HDMI_CORE : entity work.CORE_HDMI
      port map(
          pixel_clock => MCLK,
          ddr_bit_clock => hdmi_ddr_clock,
          reset =>  rst_i,
          den => hdmi_den,
          hsync => hdmi_hsync,
          vsync => hdmi_vsync,
          pixel_data => HDMI_data,
          tmds_clk => hdmi_clk,
          tmds_d0 => hdmi_d0,
          tmds_d1 => hdmi_d1,
          tmds_d2 => hdmi_d2);

end Behavioral;
