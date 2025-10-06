module SDRAM_Icarus_Test;

reg clk = 1'b0; 
reg rst = 1'b0;

always #1 clk = ~clk;

reg [15:0] in_data = 'd0;
reg [23:0] m_addr_write = 'd0;
reg [23:0] m_addr_read = 'd0;
reg m_valid_write = 1'b0;
reg m_valid_read = 1'b0;
reg Serial_access_write = 1'b0;
reg Serial_access_read = 1'b0;

wire m_ready_write;
wire m_ready_read;

wire [15:0] out_data;

//SDRAM interface
wire [12:0] DRAM_ADDR; //SDRAM address
wire [1:0] DRAM_BA; //SDRAM bank address
wire DRAM_CKE; //SDRAM clock enable
wire  DRAM_CLK;	//SDRAM clock
wire DRAM_CS_N;//SDRAM Chip Selects
wire [15:0] DRAM_DQ;  //SDRAM data bus
wire DRAM_UDQM; //SDRAM data mask lines
wire DRAM_LDQM; //SDRAM data mask lines
wire DRAM_RAS_N; //SDRAM Row address Strobe
wire DRAM_CAS_N;  //SDRAM Column address Strobe
wire DRAM_WE_N; //SDRAM write enable

pullup(DRAM_CS_N);
pullup(DRAM_RAS_N);
pullup(DRAM_CAS_N);	
pullup(DRAM_WE_N);

M_sdram_control
#(
	.INIT_PER('d1), 
	.NOP_WAITE('d1)
) 
SDRAM_Controller
(
	.clk_ref(clk),
	.rst(rst),
	.in_data(in_data),
	.m_addr_read(m_addr_read),
	.m_addr_write(m_addr_write),
	.m_valid_read(m_valid_read),
	.m_valid_write(m_valid_write),
	.Serial_access_write(Serial_access_write),
	.Serial_access_read(Serial_access_read),
	
	.m_ready_write(m_ready_write),
	.m_ready_read(m_ready_read),
	
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

M_SDRAM_Slave SDRAM_Slave
(
	.sd_addr_slave(DRAM_ADDR),
   .sd_bank_slave(DRAM_BA), 
   .sd_cke_slave(DRAM_CKE),
   .sd_clk_slave(DRAM_CLK),
   .sd_cs_n_slave(DRAM_CS_N),
   .sd_data_slave(DRAM_DQ), 
	.sd_dqmh_slave(DRAM_UDQM),
   .sd_dqml_slave(DRAM_LDQM),
   .sd_ras_n_slave(DRAM_RAS_N), 
	.sd_cas_n_slave(DRAM_CAS_N), 
   .sd_we_n_slave(DRAM_WE_N)
);

reg [15:0] data_read = 'd0;

reg [7:0] State_main = S_IDLE;

localparam 	S_IDLE = 8'd0,
				S_WRITE = 8'd1,
				S_READ = 8'd2,
				S_CHECK = 8'd3,
				S_SERIAL_WRITE_01 = 8'd4,
				S_WAITE_01 = 8'd5,
				S_SERIAL_WRITE_02 = 8'd6,
				S_SERIAL_READ_01 = 8'd7,
				S_WAITE_02 = 8'd8,
				S_SERIAL_READ_02 = 8'd9,
				S_END = 8'd253,
				S_COMPLITE = 8'd254,
				S_FAIL = 8'd255;

always @(posedge clk) 
begin
	case(State_main)
	S_IDLE:
	begin
		$write("%c[1;34m",27);
		$display("");
		$display("*********** SDRAM test start. ***********");
		$write("%c[0m",27);
		State_main <= S_WRITE;
	end
	S_WRITE: 
	begin
		if (m_ready_write)
		begin
			State_main <= S_READ;
			m_valid_write <= 1'b0;
		end
		else
		begin
			in_data <= 'hAAAA;
			m_valid_write <= 1'b1;
			m_addr_write = 'd0;
		end
	end
	S_READ:
	begin
		if (m_ready_read)
		begin
			State_main <= S_CHECK;
			data_read <= out_data;
			m_valid_read <= 1'b0;
		end
		else
		begin
			
			m_valid_read <= 1'b1;
			m_addr_read = 'd0;
		end
	end
	S_CHECK:
	begin
		if (data_read == 'hAAAA) State_main <= S_SERIAL_WRITE_01;
		else State_main <= S_FAIL;
	end
	S_SERIAL_WRITE_01:
	begin
		if (m_ready_write)
		begin
			State_main <= S_WAITE_01;
			m_valid_write <= 1'b0;
		end
		else
		begin
			in_data <= 'hAAAA;
			m_valid_write <= 1'b1;
			m_addr_write = 'd1;
			Serial_access_write <= 1'b1;
		end
	end
	S_WAITE_01:
	begin
		if (!m_ready_write) State_main <= S_SERIAL_WRITE_02;
	end
	S_SERIAL_WRITE_02:
	begin
		if (m_ready_write)
		begin
			State_main <= S_SERIAL_READ_01;
			Serial_access_write <= 1'b0;
			m_valid_write <= 1'b0;
		end
		else
		begin
			in_data <= 'hAAAA;
			m_valid_write <= 1'b1;
			m_addr_write = 'd2;
		end
	end
		
	S_SERIAL_READ_01:
	begin
		if (m_ready_read)
		begin
			
			if (out_data!= 'hAAAA)State_main <= S_FAIL;
			else State_main <= S_WAITE_02;
			m_valid_read <= 1'b0;
		end
		else
		begin
			Serial_access_read <= 1'b1;
			m_valid_read <= 1'b1;
			m_addr_read = 'd1;
		end
	end
	S_WAITE_02:
	begin
		if (!m_ready_write) State_main <= S_SERIAL_READ_02;
	end
	S_SERIAL_READ_02:
		if (m_ready_read)
		begin
			
			if (out_data!= 'hAAAA)State_main <= S_FAIL;
			else State_main <= S_COMPLITE;
			m_valid_read <= 1'b0;
			Serial_access_read <= 1'b0;
		end
		else
		begin
			
			m_valid_read <= 1'b1;
			m_addr_read = 'd2;
		end
	
	S_COMPLITE:
	begin
		$write("%c[1;32m",27);
		$display("SD Complite, time =", $stime);
		$display("%c[0m",27);
		
		State_main <= S_END;;
	end
	S_FAIL: 
	begin
		$write("%c[1;31m",27);
		$display("SD Fail, time =", $stime);
		$display("%c[0m",27);
		
		State_main <= S_END;
	end
	endcase
end

initial  #850 $finish;

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,SDRAM_Controller);
  $dumpvars(0,SDRAM_Slave);
end

//initial $monitor($stime,,, clk,, rst,,, m_valid,, m_ready,, NACK,,, sda_io,, scl_io);

endmodule 