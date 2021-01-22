library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library UNISIM;
use UNISIM.VComponents.all;

-- TEST para CORE H.D.M.I. 

entity TEST is
    Generic(
        use_HDMI_CORE: boolean :=true                                  --Usar CORE HDMI propio (true) o CORE de Digilent (falso)
    );
	Port(
	   CLOCK_125       : in std_logic;                                  -- CLK referencia de 125MHz. Pin L16 IOSTANDARD LVCMOS33
       reset           : in std_logic := '1';                           -- Reset BTN0 Pin R18 IOSTANDARD LVCMOS33
       selec_patron    : in std_logic := '0';                                -- Selección de patrón SW0 Pin G15 IOSTANDARD LVCMOS33
       selec_res_patron: in std_logic :='1';                            -- SW1 para elegir entre patrón a resolución actual ('1') y resolución original ('0')
       hdmi_out_en     : out std_logic :='1';                           -- Pin F17 IOSTANDARD LVCMOS33
       hdmi_hpd        : in std_logic :='1';                            -- Pin E18 IOSTANDARD LVCMOS33
       hdmi_clk        : out std_logic_vector(1 downto 0) :="00";       -- Pin H16 (P) H17 (N) IOSTANDARD TMDS_33
       hdmi_d0         : out std_logic_vector(1 downto 0) :="00";       -- Pin D19 (P) D20 (N) IOSTANDARD TMDS_33
       hdmi_d1         : out std_logic_vector(1 downto 0) :="00";       -- Pin C20 (P) B20 (N) IOSTANDARD TMDS_33
       hdmi_d2         : out std_logic_vector(1 downto 0) :="00");     -- Pin B19 (P) A20 (N) IOSTANDARD TMDS_33
end TEST;

architecture arq_TEST of TEST is
    signal hdmi_pixel_clock, hdmi_ddr_clock                         : std_logic :='0';
    signal hdmi_data                                                : std_logic_vector(23 downto 0) := "000000000000000000000000";           -- Dato de entrada RGB de 24 bits, se genera con patrones
    signal hdmi_den, hdmi_hsync, hdmi_vsync, hdmi_hact,hdmi_vact    : std_logic := '0';
    
    constant total_px       : natural  := 2200;
    constant total_lin      : natural  := 1125;
    constant hfp            : natural  := 88;
    constant h_sync_tamano  : natural  := 44;
    constant hbp            : natural  := 148;
    constant vfp            : natural  := 4;
    constant v_sync_tamano  : natural  := 5;
    constant vbp            : natural  := 36;
    
    constant blanking_px    : natural := hfp + h_sync_tamano + hbp;
    constant blanking_lin   : natural := vfp + v_sync_tamano + vbp;
    constant visible_px     : natural := total_px - blanking_px;
    constant visible_lin    : natural := total_lin - blanking_lin;
    
    signal hcount           : natural range 0 to total_px :=0;
    signal vcount           : natural range 0 to total_lin :=0;
    signal div_px, div_lin  : natural range 0 to 1024;   
--------------------------------------------------------------------------------------------------------------------------
component clk_wiz_0 is                                                  -- MMCM para generación de señales CLK
    port(
        clk_in   : in std_logic;
        reset    : in std_logic;
        px_clk   : out std_logic;
        ddr_clk  : out std_logic);
end component;
--------------------------------------------------------------------------------------------------------------------------
begin
    hdmi_out_en <= hdmi_hpd; 
--------------------------------------------------------------------------------------------------------------------------
    MMCM : clk_wiz_0                                                    -- Generación de señales CLK para
    port map(
        clk_in => CLOCK_125,
        reset => reset,
        px_clk => hdmi_pixel_clock,
        ddr_clk => hdmi_ddr_clock);
        
    div_px <= visible_px/8 when selec_res_patron='1' else 100;
    div_lin <= visible_lin/8 when selec_res_patron='1' else 60;
    
--------------------------------------------------------------------------------------------------------------------------   
    process (hdmi_pixel_clock, hdmi_hsync, hdmi_vsync, hdmi_hact, hdmi_vact)
	   begin
		if hdmi_pixel_clock='1' and hdmi_pixel_clock'event then         -- Sincronismo y testeo reset	      	   
			if reset = '1' then
                hcount <= 0;
                vcount <= 0;
                hdmi_hsync <='0';
                hdmi_vsync <='0';
                hdmi_hact <='0';
                hdmi_vact <='0';
			else
--------------------------------------------------------------------------------------------------------------------------             
			     if hcount = (total_px - 1) then                                       -- Recorrido de los pixels de la imagen
	               hcount <= 0;
	               if vcount = (total_lin - 1) then
	                   vcount <= 0;
	               else
	                   vcount <= vcount + 1;
	               end if;
                else
                    hcount <= hcount + 1;
                end if;
--------------------------------------------------------------------------------------------------------------------------
                if (hcount >=  h_sync_tamano + hfp + hbp) and (hcount < total_px - 1) then -- Zona activa
                    hdmi_hact <='1';
                else 
                    hdmi_hact <='0';
                end if;
                if (vcount >= v_sync_tamano + vfp + vbp) and vcount < (total_lin) then  
                    hdmi_vact <='1';
                else
                    hdmi_vact <='0';
                end if;
--------------------------------------------------------------------------------------------------------------------------
                if hcount >= hfp and hcount < h_sync_tamano + hfp then               -- Generación de señales de sincronismo
                    hdmi_hsync <= '1';                                                         -- horizontal y vertical
                else 
                    hdmi_hsync <= '0';
                end if;
                if vcount >= vfp and vcount < v_sync_tamano + vfp then  
                    hdmi_vsync <= '1';
                else
                    hdmi_vsync <= '0';
                end if;
---------------------------------------------------------------------------------------------------------------------------                                    
		    end if; 
		end if;
	    hdmi_den <= hdmi_hact and hdmi_vact;
	end process;    
--------------------------------------------------------------------------------------------------------------------------
    process(hcount,vcount, selec_patron)                       -- Dibujo de patrones
	   begin
	       if (selec_patron = '0') then                                                             -- Square pattern test
            if (hcount >= blanking_px + 8*div_px or vcount >= blanking_lin + 8*div_lin)then
                hdmi_data <= "000000000000000000000000";                                            -- Negro fuera de patrón 
            elsif ((hcount < blanking_px + 1*div_px and vcount < blanking_lin + 1*div_lin) or
                (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 7*div_lin)) then
                hdmi_data <= "111111111111111111111111";                                            -- Blanco
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 2*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 1*div_lin) or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 7*div_lin) or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 6*div_lin) then
                hdmi_data <= "111111111111111100000000";                                            -- Amarillo
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 3*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 2*div_lin) or
                  (hcount < blanking_px + 3*div_px and vcount < blanking_lin + 1*div_lin) or
                  (hcount >= blanking_px + 5*div_px and vcount >= blanking_lin + 7*div_lin) or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 6*div_lin) or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 5*div_lin) then
                hdmi_data <= "000000001111111111111111";                                            -- Cian
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 4*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 3*div_lin) or
                  (hcount < blanking_px + 3*div_px and vcount < blanking_lin + 2*div_lin) or
                  (hcount < blanking_px + 4*div_px and vcount < blanking_lin + 1*div_lin)or
                  (hcount >= blanking_px + 4*div_px and vcount >= blanking_lin + 7*div_lin) or
                  (hcount >= blanking_px + 5*div_px and vcount >= blanking_lin + 6*div_lin) or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 5*div_lin) or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 4*div_lin) then
                hdmi_data <= "000000001111111100000000";                                            -- Verde
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 5*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 4*div_lin) or
                  (hcount < blanking_px + 3*div_px and vcount < blanking_lin + 3*div_lin) or
                  (hcount < blanking_px + 4*div_px and vcount < blanking_lin + 2*div_lin) or
                  (hcount < blanking_px + 5*div_px and vcount < blanking_lin + 1*div_lin) or
                  (hcount >= blanking_px + 3*div_px and vcount >= blanking_lin + 7*div_lin)or
                  (hcount >= blanking_px + 4*div_px and vcount >= blanking_lin + 6*div_lin) or
                  (hcount >= blanking_px + 5*div_px and vcount >= blanking_lin + 5*div_lin)or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 4*div_lin) or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 3*div_lin) then
                hdmi_data <= "111111110000000011111111";                                            -- Magenta
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 6*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 5*div_lin) or
                  (hcount < blanking_px + 3*div_px and vcount < blanking_lin + 4*div_lin)or
                  (hcount < blanking_px + 4*div_px and vcount < blanking_lin + 3*div_lin) or
                  (hcount < blanking_px + 5*div_px and vcount < blanking_lin + 2*div_lin)or
                  (hcount < blanking_px + 6*div_px and vcount < blanking_lin + 1*div_lin) or
                  (hcount >= blanking_px + 2*div_px and vcount >= blanking_lin + 7*div_lin)or
                  (hcount >= blanking_px + 3*div_px and vcount >= blanking_lin + 6*div_lin) or
                  (hcount >= blanking_px + 4*div_px and vcount >= blanking_lin + 5*div_lin)or
                  (hcount >= blanking_px + 5*div_px and vcount >= blanking_lin + 4*div_lin) or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 3*div_lin)or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 2*div_lin) then
                hdmi_data <= "111111110000000000000000";                                            -- Rojo
            elsif (hcount < blanking_px + 1*div_px and vcount < blanking_lin + 7*div_lin) or
                  (hcount < blanking_px + 2*div_px and vcount < blanking_lin + 6*div_lin) or
                  (hcount < blanking_px + 3*div_px and vcount < blanking_lin + 5*div_lin) or
                  (hcount < blanking_px + 4*div_px and vcount < blanking_lin + 4*div_lin) or
                  (hcount < blanking_px + 5*div_px and vcount < blanking_lin + 3*div_lin) or
                  (hcount < blanking_px + 6*div_px and vcount < blanking_lin + 2*div_lin) or
                  (hcount < blanking_px + 7*div_px and vcount < blanking_lin + 1*div_lin) or
                  (hcount >= blanking_px + 1*div_px and vcount >= blanking_lin + 7*div_lin) or
                  (hcount >= blanking_px + 2*div_px and vcount >= blanking_lin + 6*div_lin) or
                  (hcount >= blanking_px + 3*div_px and vcount >= blanking_lin + 5*div_lin) or
                  (hcount >= blanking_px + 4*div_px and vcount >= blanking_lin + 4*div_lin) or
                  (hcount >= blanking_px + 5*div_px and vcount >= blanking_lin + 3*div_lin) or
                  (hcount >= blanking_px + 6*div_px and vcount >= blanking_lin + 2*div_lin) or
                  (hcount >= blanking_px + 7*div_px and vcount >= blanking_lin + 1*div_lin) then
                hdmi_data <= "000000000000000011111111";                                            -- Azul
             else
                hdmi_data <= "000000000000000000000000";                                            -- Negro
            end if;
           else                                                         -- Bar pattern test
            if (hcount < blanking_px + 1*div_px) then
                hdmi_data <= "111111111111111111111111";                -- Blanco
            elsif (hcount < blanking_px + 2*div_px) then
                hdmi_data <= "111111111111111100000000";                -- Amarillo
            elsif (hcount < blanking_px + 3*div_px) then
                hdmi_data <= "000000001111111111111111";                -- Cian
            elsif (hcount < blanking_px + 4*div_px) then
                hdmi_data <= "000000001111111100000000";                -- Verde
            elsif (hcount < blanking_px + 5*div_px) then
                hdmi_data <= "111111110000000011111111";                -- Magenta
            elsif (hcount < blanking_px + 6*div_px) then
                hdmi_data <= "111111110000000000000000";                -- Rojo
            elsif (hcount < blanking_px + 7*div_px) then
                hdmi_data <= "000000000000000011111111";                -- Azul
            else
                hdmi_data <= "000000000000000000000000";                -- Negro
            end if;
           end if;
       end process;
--------------------------------------------------------------------------------------------------------------------------
HDMI_CORE_Gen: if use_HDMI_CORE generate
    HDMI_CORE : entity work.CORE_HDMI                                           -- Llamada al CORE
      port map(
          pixel_clock => hdmi_pixel_clock,
          ddr_bit_clock => hdmi_ddr_clock,
          reset => reset,
          den => hdmi_den,
          hsync => hdmi_hsync,
          vsync => hdmi_vsync,
          pixel_data => hdmi_data,
          tmds_clk => hdmi_clk,
          tmds_d0 => hdmi_d0,
          tmds_d1 => hdmi_d1,
          tmds_d2 => hdmi_d2);
end generate;
--------------------------------------------------------------------------------------------------------------------------
HDMI_REFCORE_Gen: if not use_HDMI_CORE generate
    HDMI_REFCORE : entity work.rgb2dvi
        generic map(
            kGenerateSerialClk=>false
        )
        port map(
            TMDS_Clk_p => hdmi_clk(1),
            TMDS_Clk_n => hdmi_clk(0),
            TMDS_Data_p(2) => hdmi_d2(1), TMDS_Data_p(1) => hdmi_d1(1), TMDS_Data_p(0) =>  hdmi_d0(1),
            TMDS_Data_n(2) => hdmi_d2(0), TMDS_Data_n(1) => hdmi_d1(0), TMDS_Data_n(0) => hdmi_d0(0),
            
            aRst => reset,
            aRst_n => '1',
            
            vid_pData(23 downto 16) => hdmi_data(23 downto 16), --byte R
            vid_pData(7 downto 0) => hdmi_data(15 downto 8), --byte G
            vid_pData(15 downto 8) => hdmi_data(7 downto 0), --byte B
            vid_pVDE => hdmi_den,
            vid_pHSync => hdmi_hsync,
            vid_pVSync => hdmi_vsync,
            PixelClk => hdmi_pixel_clock,
            
            SerialClk => hdmi_ddr_clock);
end generate;

end arq_TEST;