module MONDELBROTE
 # (
		parameter MONDELBROTE_DEPTH = 100,
		parameter INICIALIZATION_EN = 1
   )
(   
	input wire clk,
	input wire rst,
	input wire m_ready,
	
	output reg m_we = 1'b0,
	output wire [23:0] m_addr,
	output reg m_valid = 1'b0,
	output wire [15:0]o_data,
	output reg	Serial_access = 1'b0
	
);
 
reg [10:0] H_count = 0;
reg [10:0] V_count = 0;
wire PixReady;
reg Calk;

 
assign m_addr[10:0] = H_count;
assign m_addr[21:11] = V_count;
assign m_addr[23:22] = 0;

MONDELBROTE_BUILDER
#(
	.MONDELBROTE_DEPTH(MONDELBROTE_DEPTH)
)
	BUILDER
(
	.clk(clk), 
	.rst(rst),
	.H_count(H_count),
	.V_count(V_count),
	.Calk(Calk),
	.PixReady(PixReady),
	.PixColor(o_data)
);	
 
reg [4:0] WriteState;



localparam  S_DATA_CALCULATE = 4'd0,
				S_WRITE_READY = 4'd1,
				S_WRITE_POST = 4'd3,
				S_WRITE_END = 4'd4; 
		
				


always@ (posedge clk)
begin 
	if (rst)
	begin
		H_count <= 0;
		V_count <= 0;
		WriteState <= S_DATA_CALCULATE;

		
	end
	
	else 
	begin
	
	case(WriteState)
		
		S_DATA_CALCULATE:
		begin
			
			if (!INICIALIZATION_EN) WriteState <= S_WRITE_END;
			else
			begin
				Calk <= 1'b1;
				m_we <= 1'b1;
				Serial_access <= 1'b1;
				
				if (PixReady)
				begin
					WriteState <= S_WRITE_READY;
					Calk <= 1'b0;
				end
			end
		end
		S_WRITE_READY:
		begin 
			if (m_ready)
			begin
				m_valid <= 1'b0;
			
				WriteState <= S_WRITE_POST;
			end
			else m_valid <= 1'b1;
		end
		
		S_WRITE_POST:
		begin
			
			if (V_count != 600)
			begin 
				if (H_count != 800) H_count <= H_count + 1'b1;
				else 
				begin
					H_count <= 0;
					V_count <= V_count + 1'b1;
				end
				WriteState <= S_DATA_CALCULATE;
			end
			else WriteState <= S_WRITE_END;
			
		end
		
		S_WRITE_END: 
		begin
			m_we <= 1'b0;
			Serial_access <= 1'b0;
		end
	endcase
		
		
		
	end
end
 

  
endmodule 

module MONDELBROTE_BUILDER
#(
	parameter MONDELBROTE_DEPTH = 200
)
(
	input wire clk,
	input wire rst,
	input wire [10:0]V_count,
	input wire [10:0]H_count,
	input wire Calk,
	
	output reg PixReady,
	output reg  [15:0] PixColor
	
);


wire [31:0] X;
wire [31:0] ci_temp;
wire [31:0] ci;

wire [31:0] Y;
wire [31:0] cr_temp;
wire [31:0] cr;

reg [31:0] zr = 0;
reg [31:0] zi = 0;

wire [31:0] zr_v;
wire [31:0] zi_v;
wire [31:0] tmp;

wire [31:0] zrsqur;
wire [31:0] zisqur;
wire [31:0] zizrpruduct;
wire [31:0] twozizrpruduct;
wire [31:0] cmp;
reg [31:0] k;
reg [31:0] m;



wire Lim_over;

localparam TWO = 32'b01000000000000000000000000000000; //2
localparam THREE = 32'b01000011100101100000000000000000; //0.5 * 600 =300
localparam X_OFF_ON_WEIGHT = 32'b01000100000111000000000000000000; //0.78 * 800 = 624
localparam MAX_LIMIT = 32'b01000111110000110101000000000000;// 100000

reg [11:0]   ColorPallet [45:0];
initial begin
//RED
ColorPallet[0] = 12'b000000000000;
ColorPallet[1] = 12'b000000000001;
ColorPallet[2] = 12'b000000000010;
ColorPallet[3] = 12'b000000000011;
ColorPallet[4] = 12'b000000000100;
ColorPallet[5] = 12'b000000000101;
ColorPallet[6] = 12'b000000000110;
ColorPallet[7] = 12'b000000000111;
ColorPallet[8] = 12'b000000001000;
ColorPallet[9] = 12'b000000001001;
ColorPallet[10] = 12'b000000001010;
ColorPallet[11] = 12'b000000001011;
ColorPallet[12] = 12'b000000001100;
ColorPallet[13] = 12'b000000001101;
ColorPallet[14] = 12'b000000001110;
ColorPallet[15] = 12'b000000001111;
//Yellow
ColorPallet[16] = 12'b000000011111;
ColorPallet[17] = 12'b000000101111;
ColorPallet[18] = 12'b000000111111;
ColorPallet[19] = 12'b000001001111;
ColorPallet[20] = 12'b000001011111;
ColorPallet[21] = 12'b000001101111;
ColorPallet[22] = 12'b000001111111;
ColorPallet[23] = 12'b000010001111;
ColorPallet[24] = 12'b000010011111;
ColorPallet[25] = 12'b000010101111;
ColorPallet[26] = 12'b000010111111;
ColorPallet[27] = 12'b000011001111;
ColorPallet[28] = 12'b000011011111;
ColorPallet[29] = 12'b000011101111;
ColorPallet[30] = 12'b000011111111;
//White
ColorPallet[31] = 12'b000111111111;
ColorPallet[32] = 12'b001011111111;
ColorPallet[33] = 12'b001111111111;
ColorPallet[34] = 12'b010011111111;
ColorPallet[35] = 12'b010111111111;
ColorPallet[36] = 12'b011011111111;
ColorPallet[37] = 12'b011111111111;
ColorPallet[38] = 12'b100011111111;
ColorPallet[39] = 12'b100111111111;
ColorPallet[40] = 12'b101011111111;
ColorPallet[41] = 12'b101111111111;
ColorPallet[42] = 12'b110011111111;
ColorPallet[43] = 12'b110111111111;
ColorPallet[44] = 12'b111011111111;
ColorPallet[45] = 12'b111111111111;
end


reg [4:0] CalkCount = 5'd0;
reg [3:0] WriteState = 0;



localparam   S_WAIT = 4'd0,
				S_INT_CONVERT = 4'd1,
				S_CI_AND_CR_CALK = 4'd2,
				S_CI_AND_CR_CALK_2 = 4'd3,
				S_ZI_ZR_MULL = 4'd4,
				S_TWO_ZI_ZR_MULL = 4'd5,
				S_FINAL_CALK = 4'd6,
				S_FINAL_CALK_2 = 5'd7,
				S_CAMPARE = 4'd8,
				S_SET_COLOR  = 4'd9;
				



always@ (posedge clk)
begin
	if (rst)
	begin
		WriteState <= S_WAIT;
		
		
	end
	else
	begin
		case(WriteState)
		S_WAIT:
		begin
			CalkCount <= 5'd0;
			PixReady <= 1'b0;
			zr <= 0;
			zi <= 0;
			k <= 0;
			if (Calk) 
			begin 
				
				WriteState <= S_INT_CONVERT;
			end
			
		end
		
		S_INT_CONVERT:
		begin
			
			if (CalkCount != 1)
			begin
				FtoI_X_en <= 1'b1;
				FtoI_Y_en <= 1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				FtoI_X_en <= 1'b0;
				FtoI_Y_en <= 1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_CI_AND_CR_CALK;
			end
		end
		S_CI_AND_CR_CALK:
		begin
			if (CalkCount != 7)
			begin
				
				Addr_ci_tmp_en <= 1'b1;
				Add_cr_tmp_en <= 1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				Addr_ci_tmp_en <= 1'b0;
				Add_cr_tmp_en <= 1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_CI_AND_CR_CALK_2;
			end
		end
		S_CI_AND_CR_CALK_2:
		begin
			if (CalkCount != 6)
			begin
				
				Div_ci_en <= 1'b1;
				Div_cr_en <=  1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				Div_ci_en <= 1'b0;
				Div_cr_en <=  1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_ZI_ZR_MULL;
			end
			
		end
			
		S_ZI_ZR_MULL:
		begin
			if (CalkCount != 6)
			begin
				Zr_mul_en <=  1'b1;
				Zi_mul_en <=  1'b1;
				ZiZr_mul_en <=  1'b1;
				
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				Zr_mul_en <=  1'b0;
				Zi_mul_en <=  1'b0;
				ZiZr_mul_en <=  1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_TWO_ZI_ZR_MULL;
			end
		end
		S_TWO_ZI_ZR_MULL:
		begin
			if (CalkCount != 6)
			begin
				ZiZr_mul_two_en <= 1'b1;
			
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				ZiZr_mul_two_en <= 1'b0;
			
				CalkCount <= 5'd0;
				WriteState <= S_FINAL_CALK;
			end
		end
		S_FINAL_CALK:
		begin
			if (CalkCount != 7)
			begin
				Add_tmp_en <= 1'b1;
				Add_zi_en <= 1'b1;
				Add_cmp_en <= 1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				Add_tmp_en <= 1'b0;
				Add_zi_en <= 1'b0;
				Add_cmp_en <= 1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_FINAL_CALK_2;
			end
		end
		
		S_FINAL_CALK_2:
		begin
			if (CalkCount != 8) 
			begin
				Add_zr_en = 1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				Add_zr_en = 1'b0;
				
				CalkCount <= 5'd0;
				WriteState <= S_CAMPARE;
			end
		end
		
		
			
		S_CAMPARE:
		begin
			if (CalkCount != 2)
			begin
				comper_res_en = 1'b1;
				
				CalkCount <= CalkCount + 1'b1;
			end
			else
			begin
				comper_res_en = 1'b0;
				
				if (Lim_over)
				begin
					
					WriteState <= S_SET_COLOR;
					m = k % 46;
				end
				else 
				begin
					if (k < MONDELBROTE_DEPTH)
					begin
						WriteState <= S_ZI_ZR_MULL;
						zr <= zr_v;
						zi <= zi_v;
						k <= k + 1'b1;
					end
					else
					begin
						
						m <= 0;
						WriteState <= S_SET_COLOR;
					end
				end
			end
		end
		S_SET_COLOR:
		begin
			PixColor <= ColorPallet[m];
			WriteState <= S_WAIT;
			PixReady <= 1'b1;
		end
			
		
		endcase
	
	end
end


	
//S_INT_CONVERT..................

reg FtoI_X_en = 1'b0;
reg FtoI_Y_en = 1'b0;

FP_I_To_F FtoI_X
(
	.clk_en(FtoI_X_en),
	.clock(clk),
	.dataa(H_count),
	.result(Y)
);

FP_I_To_F FtoI_Y
(
	.clk_en(FtoI_Y_en),
	.clock(clk),
	.dataa(V_count),
	.result(X)
);

//S_CI_AND_CR_CALK......................................

reg Addr_ci_tmp_en = 1'b0;
reg Add_cr_tmp_en = 1'b0;


FP_ADD Addr_ci_tmp
(
	.add_sub(0),
	.clk_en(Addr_ci_tmp_en),
	.clock(clk),
	.dataa(X),
	.datab(THREE),
	.result(ci_temp)
);

FP_ADD Add_cr_tmp
( 
	.add_sub(0),
	.clk_en(Add_cr_tmp_en),
	.clock(clk),
	.dataa(Y),
	.datab(X_OFF_ON_WEIGHT),
	.result(cr_temp)
);

//S_CI_AND_CR_CALK_2......................................

reg Div_ci_en = 1'b0;
reg Div_cr_en =  1'b0;

FP_DIV Div_ci
(
	.clk_en(Div_ci_en),
	.clock(clk),
	.dataa(ci_temp),
	.datab(THREE),
	.result(ci)
);



FP_DIV Div_cr
(
	.clk_en(Div_cr_en),
	.clock(clk),
	.dataa(cr_temp),
	.datab(THREE),
	.result(cr)
);

//S_ZI_ZR_MULL.......................

reg Zr_mul_en = 1'b0;
reg Zi_mul_en = 1'b0;
reg ZiZr_mul_en = 1'b0;

FP_MUL Zr_mul
(
	.clk_en(Zr_mul_en),
	.clock(clk),
	.dataa(zr),
	.datab(zr),
	.result(zrsqur)
);

FP_MUL Zi_mul
(
	.clk_en(Zi_mul_en),
	.clock(clk),
	.dataa(zi),
	.datab(zi),
	.result(zisqur)
);

FP_MUL ZiZr_mul
(
	.clk_en(ZiZr_mul_en),
	.clock(clk),
	.dataa(zi),
	.datab(zr),
	.result(zizrpruduct)
);

//S_TWO_ZI_ZR_MULL.................................
reg ZiZr_mul_two_en = 1'b0;

FP_MUL ZiZr_mul_two
(
	.clk_en(ZiZr_mul_two_en),
	.clock(clk),
	.dataa(zizrpruduct),
	.datab(TWO),
	.result(twozizrpruduct)
);

//S_FINAL_CALK................................
reg Add_tmp_en = 1'b0;
reg Add_zi_en = 1'b0;

FP_ADD Add_tmp
(
	.add_sub(0),
	.clk_en(Add_tmp_en),
	.clock(clk),
	.dataa(zrsqur),
	.datab(zisqur),
	.result(tmp)
);

reg Add_cmp_en = 1'b0;

FP_ADD Add_cmp
(
	.add_sub(1),
	.clk_en(Add_cmp_en),
	.clock(clk),
	.dataa(zrsqur),
	.datab(zisqur),
	.result(cmp)
);

FP_ADD Add_zi
(
	.add_sub(1),
	.clk_en(Add_zi_en),
	.clock(clk),
	.dataa(twozizrpruduct),
	.datab(ci),
	.result(zi_v)
);

//S_FINAL_CALK_2................................

reg Add_zr_en = 1'b0;

FP_ADD Add_zr
(
	.add_sub(1),
	.clk_en(Add_zr_en),
	.clock(clk),
	.dataa(tmp),
	.datab(cr),
	.result(zr_v)
);


//S_CAMPARE................................
reg comper_res_en = 1'b0;

FP_COMP comper_res
(
	.clk_en(comper_res_en),
	.clock(clk),
	.dataa(cmp),
	.datab(MAX_LIMIT),
	.agb(Lim_over)
);

endmodule 