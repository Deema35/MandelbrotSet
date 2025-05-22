module VideoAdapter_M
#(
	parameter ENDSTRING = 11'd1055,
	parameter ENDFRAME = 11'd627
	
)

(
	input wire clk,
	input wire rst,
	input wire [15:0]  Pix_color,
	
	output reg Hsync,
	output reg Vsync,
	
	output wire [3:0]  Red,
	output wire [3:0]  Green,
	output wire [3:0]  Blue,
	
	
	output reg Hblank,
	output reg Vblank,
	
	output reg [10:0] H_count,
	output reg [10:0] V_count
	
);


wire blank;

assign blank = Hblank | Vblank;

assign Red[3:0] = blank ? 4'b0000 : Pix_color[3:0];

assign Green[3:0] = blank ? 4'b0000 : Pix_color[7:4];

assign Blue[3:0] = blank ? 4'b0000 : Pix_color[11:8];


HorizontalCounter 
#(
	.ENDSTRING(ENDSTRING)
)
H_Counter
(
	.clk(clk),
	.rst(rst),
	.DATA(H_count)
);



VerticalCounter
#(
	.ENDSTRING(ENDSTRING),
	.ENDFRAME(ENDFRAME)
)
 V_Counter
(
	.clk(clk),
	.rst(rst),
	.Hor_count(H_count),
	.DATA(V_count),
);

always @(posedge clk ) 
begin 
	
	if (rst)
	begin
	
		Hblank <= 1'b0;
		Hsync <= 1'b0;
		
	end
	else
	begin
		
		case (H_count)
		
			799: Hblank <= 1'b1;
			
			839: Hsync <= 1'b1;
			
			967: Hsync <= 1'b0;
			
			ENDSTRING: Hblank <= 1'b0;
			
		endcase
		
		case (V_count)
		
			599: Vblank <= 1'b1;
			
			600: Vsync <= 1'b1;
			
			604: Vsync <= 1'b0;
			
			ENDFRAME: Vblank <= 1'b0;
			
		endcase
	end
		

end
endmodule

module String_Buffer
#(
	parameter ENDFRAME = 11'd1055
)
(
	input wire clk,
	input wire rst,
	input wire [15:0] DATA,
	input wire DATA_valid,
	input wire [10:0] V_count,
	input wire [10:0] H_count,
	input wire Hblank,
	input wire Write_Flag,
	
	output wire [15:0]  Pix_color,
	output wire [23:0]   DATA_addr,
	output wire	DATA_in_ready,
	output wire	Serial_access = 'b0

	
	
);

assign Pix_color = string_buf[H_count[10:0]];


reg [15:0]   string_buf [800:0];

reg [10:0]DATA_Counter = 0;
reg [10:0]DATA_String_Counter = 0;

assign DATA_addr[10:0] = DATA_Counter[10:0];
assign DATA_addr[21:11] = DATA_String_Counter[10:0];
assign DATA_addr[23:22] = 0;

reg [3:0]BufferState;

parameter   S_READBEGIN = 4'd0,
				S_READSTRING = 4'd1,
				S_READREADY = 4'd2;



always @(posedge clk)
begin
	if (rst)
	begin
	DATA_Counter <= 0;
	DATA_String_Counter <= 0;
	BufferState <= S_READBEGIN;
	
	end
	
	else 
	begin
	
		case(BufferState)
			S_READBEGIN:
			begin
				BufferState <= S_READSTRING;
				DATA_Counter <= 'd0;
				Serial_access <= 'b1;
			end
			
			S_READSTRING:
			begin
				
				if (DATA_valid)
				begin
					string_buf[DATA_Counter] <= DATA;
					DATA_Counter <= DATA_Counter + 1;
					DATA_in_ready <= 1'b0;
					
				end
				else DATA_in_ready <= 1'b1;
				
			if (DATA_Counter == 'd800) BufferState <= S_READREADY;
					
			end
			
			S_READREADY:
			begin
				Serial_access <= 'b0;
				if (Hblank)
				begin
					
					
					if (V_count < 'd599)
					begin 
						DATA_String_Counter <= V_count + 1'b1;
						BufferState <= S_READBEGIN;
					end

					else if (V_count == (ENDFRAME - 1'b1))
					begin
						DATA_String_Counter <= 0;
						BufferState <= S_READBEGIN;
					end
				end
			
			end
		endcase
		
	end
	
end



endmodule 

module HorizontalCounter
#(
	parameter ENDSTRING = 0
)
( 
	input wire clk,
	input wire rst,
	output reg [10:0]DATA
);


always @(posedge clk ) 
begin 

	if (rst) DATA <= 11'd0;
		
	else
	begin
	
	  if(DATA == ENDSTRING) DATA <= 11'd0;
		 
	  else DATA <= DATA + 1'd1; 
	  
	end
		 
end

endmodule 

module VerticalCounter
#(
	parameter ENDFRAME = 0,
	parameter ENDSTRING = 0
)
( 
	input wire clk, 
	input wire rst,
	input wire [10:0]Hor_count,
	output reg [10:0]DATA
);


always @(posedge clk ) 
begin 
	if (rst) DATA <= 11'd0;
	
	else
	begin
	
	  if(DATA == ENDFRAME) DATA <= 11'd0;
		 
	  else if (Hor_count == ENDSTRING)  DATA <= DATA + 1'd1; 
	  
	end
		 
end
		 

endmodule 
