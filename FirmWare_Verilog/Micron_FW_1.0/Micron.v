

// SDR-Micron Project
// David Fainitski, N7DDC
// 2016  Berlin
// 2019 Seattle




module Micron (
   //
   // USB FT232HQ interface
	inout [7:0] usb_data,
	output n_RD,
	output n_WR,
	input n_RXF,
	input n_TXE,
	output n_SIWU,
	output n_OE,
	input USB_CLK_60MHz,
	//
   // ADC interface AD9649/9629
	input [13:0] ADC_data,
	input ADC_clock,
	input ADC_OF,
	output ADC_SCLK,
	output ADC_SDATA,
	output ADC_SEN,
	//
	// Attenuator
	output ATT_10,
	output ATT_20,
	//
	// BPF
	output [2:0] BPF,
	//
	// I2C master interface to clock generator
	inout SDA,
	inout SCL,
	//
	//  Clock routing
	output _10MHz_out,
	input _10MHz_in,
	input PLL_10MHz,
	output _usb_out,
	input _usb_in,
	//
	// LEDs
	output LED_PWR,
	output LED_CLIP,
	output test_led1,
	output test_led2,
	output test1,
	output test2,
	output test3,
	output test4

	
);


   parameter [7:0] FW1 = "1"; // First digit
	parameter [7:0] FW2 = "0"; // Second digit
	//
	assign LED_PWR = m_reset & pll2_locked;
	
	assign ATT_10 = rx_on & (ATT==10 | ATT==30);
	assign ATT_20 = rx_on & (ATT==20 | ATT==30);
	
	assign _10MHz_out = _10MHz_in;
	assign _usb_out = USB_CLK_60MHz;
   //
	adc_init a_init(clock_02, m_reset, ADC_SCLK, ADC_SDATA, ADC_SEN, rx_on, rx_freq[31:16]);
	//
	clkgen_init c_init(clock_02, m_reset, SDA, SCL);
	//
	bpf_ctrl bpf(rx_freq[31:16], BPF);
	//
	wire clock_76M, usb_clock, clock_02;
	wire pll1_locked, pll2_locked;
	
	PLL1 pll1 (ADC_clock, clock_76M, pll1_locked);
	PLL2 pll2 (_usb_in, usb_clock, clock_02, pll2_locked);

	
	//assign test1 = ADC_clock;
	//assign test2 = clock_76M;
   //assign test3 = clock_48M;	
	//assign test4 = usb_clock;
   //
	wire m_reset;
	master_reset mres (clock_02, pll2_locked, m_reset);
   //
	clip_led clip (clock_02, ADC_OF, LED_CLIP);
	//
	
	// ADC memory for samples, 2 pages per 256 words by 48 bits 
	wire [47:0] adc_ram_wr_data, adc_ram_rd_data;
	wire [7:0] adc_ram_wr_addr, adc_ram_rd_addr;
	wire adc_ram_wen;
	adc_ram ram1 (.data(adc_ram_wr_data), .wraddress(adc_ram_wr_addr), .wrclock(~clock_76M), .wren(adc_ram_wen),
                   	.rdaddress(adc_ram_rd_addr), .rdclock(usb_clock), .q(adc_ram_rd_data));
	//
	
	// BS memory for samples, 8192 bytes, 4096 16bit words
	wire [15:0] bs_ram_wr_data, bs_ram_rd_data;
	wire [11:0] bs_ram_wr_addr, bs_ram_rd_addr;
	wire bs_ram_wen;
	bs_ram ram2 (.data({adc_data_reg, 2'd0}), .wraddress(bs_ram_wr_addr), .wrclock(ADC_clock), .wren(!bs_ready), 
	                    .rdaddress(bs_ram_rd_addr), .rdclock(usb_clock), .q(bs_ram_rd_data));
	//
	
	wire rx_on, bs_on;
	wire [7:0] ATT;
   usb_control #(FW1, FW2) u_con(usb_clock, m_reset, usb_data, n_RD, n_WR, n_RXF, n_TXE, n_SIWU, n_OE, 
	                   adc_ram_rd_data, adc_ram_rd_addr, adc_ram_block, bs_ram_rd_data, bs_ram_rd_addr, bs_ready,
	                   LED_CLIP, rx_on, bs_on, bs_period, ATT, rx_freq, rx_rate, test1, test2, test3, test4);
   //
	
	reg signed [13:0] adc_data_reg;
	always @(posedge clock_76M) adc_data_reg <= ADC_data;
	//
	
   wire adc_ram_block;
	wire [31:0] rx_freq;
	wire [7:0] rx_rate;
	receiver rcv_inst (clock_76M, rx_on, adc_data_reg, rx_freq, rx_rate, 
              	   adc_ram_wr_data, adc_ram_wr_addr, adc_ram_wen, adc_ram_block, test_led1, test_led2); 
	//

	wire bs_ready;
	wire [7:0] bs_period;
	wire rawRamReset, rawRamReady;
	bandscope bs_inst (clock_76M, bs_on, bs_period, bs_ready, bs_ram_wr_addr, clock_02);		


	
endmodule 


