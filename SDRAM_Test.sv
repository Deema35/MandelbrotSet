module SDRAM_Test 
#(
	parameter      ADDR_W = 24,
	parameter      DATA_W = 16,
	
	//Video Adapter
	parameter ENDSTRING = 11'd1055,
	parameter ENDFRAME = 11'd627,
	parameter ADDR_WIDTH = 14,
	parameter DATA_WIDTH = 6
)
(
	input wire clk_50,
	input wire RESET_N,
	input wire KEY,
	output wire LEDR,
	
	//SDRAM
	output wire   [12:0]	DRAM_ADDR, //SDRAM address
   output wire   [1:0] 	DRAM_BA, //SDRAM bank address
   output wire        DRAM_CKE, //SDRAM clock enable
   output wire           DRAM_CLK,	//SDRAM clock
   output wire    		DRAM_CS_N,//SDRAM Chip Selects
   inout  tri   [15:0]	DRAM_DQ,  //SDRAM data bus
	output wire           DRAM_UDQM, //SDRAM data mask lines
   output wire           DRAM_LDQM, //SDRAM data mask lines
   output wire        DRAM_RAS_N, //SDRAM Row address Strobe
	output wire        DRAM_CAS_N,  //SDRAM Column address Strobe
   output wire        DRAM_WE_N, //SDRAM write enable
	
	//Video interfase
	output wire Hsync,
	output wire Vsync,
	output wire [3:0]  Red,
	output wire [3:0]  Green,
	output wire [3:0]  Blue
);

assign LEDR = (!RESET_N) ? 1'b1 : 1'b0;


//Video
wire clk_120;
wire clk_40;
wire [15:0]Pix_color;
wire [10:0] H_count;
wire [10:0] V_count;
wire Hblank;
wire flag;

PLL PLL_Loop
(
	.inclk0(clk_50),
	.c0(clk_120),
	.c1(clk_40)
);



VideoAdapter_M 
#(
	.ENDSTRING(ENDSTRING),
	.ENDFRAME(ENDFRAME)
)
Video
(
	.clk(clk_40),
	.rst(!RESET_N),
	.Pix_color(Pix_color),
	.Hsync(Hsync),
	.Vsync(Vsync),
	.Red(Red),
	.Green(Green),
	.Blue(Blue),
	.H_count(H_count),
	.V_count(V_count),
	.Hblank(Hblank)
	
);

String_Buffer
#(
	.ENDFRAME(ENDFRAME)
)
Video_Buffer
(
	.clk(clk_120),
	.rst(!RESET_N),
	.DATA(out_data),
	.DATA_valid(m_ready),
	.H_count(H_count),
	.V_count(V_count),
	.Hblank(Hblank),
	.Write_Flag(write_flag),
	.Pix_color(Pix_color),
	.DATA_addr(m_addr_read),
	.DATA_in_ready(m_valid_read)

);

//SDRAM
wire m_we;
wire m_valid;
wire m_ready;
wire[15:0] out_data;
wire [23:0] m_addr;

sdram_control   
SDRAM_Controller
(
	.clk_ref(clk_120),
	.rst(!RESET_N),
	.in_data(Pic_data),
	.m_addr(m_addr),
	.m_we(m_we),
	.m_valid(m_valid),
	
	.m_ready(m_ready),
	.out_data(out_data),
	
	.sd_cke(DRAM_CKE),
	.sd_clk(DRAM_CLK),
	.sd_dqml(DRAM_LDQM),
	.sd_dqmh(DRAM_UDQM),
	.sd_cas_n(DRAM_CAS_N),
	.sd_ras_n(DRAM_RAS_N),
	.sd_we_n(DRAM_WE_N),
	.sd_cs_n(DRAM_CS_N),
	.sd_addr({DRAM_BA, DRAM_ADDR}),
	.sd_data(DRAM_DQ)
	
);

//Mem copy

reg[15:0] Pic_data;
wire m_valid_write;
wire m_valid_read; 
wire [23:0] m_addr_write;
wire [23:0] m_addr_read;
reg copy_flag;

assign m_valid = copy_flag ? m_valid_write : m_valid_read;
assign m_addr = copy_flag ? m_addr_write : m_addr_read;


MONDELBROTE Mondelbrote
(
	.clk(clk_120),
	.rst(!RESET_N),
	.m_ready(m_ready),

	.m_we(m_we),
	.copy_flag(copy_flag),
	.m_addr(m_addr_write),
	.m_valid(m_valid_write),
	.o_data(Pic_data)

);


endmodule 





