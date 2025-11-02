module axi_lite_read (
     // Global Signals
     input ACLK,
     input ARSTn,

     // Signals by Master
     input [31:0] ARADDER,
     input        ARVALID,       // ADDRESS SENT ON CHANNEL BY MASTER IS VALID
     output reg  ARREADY,       // MASTER IS READY TO GET RESPONSE 

     // Signals by Slave
     input             RREADY,
     output reg [31:0] RDATA,
     output reg [1:0]  RRESP,   // Response signal, 00 for OKAY
     output reg        RVALID     // DATA SENT BY SLAVE IS VALID
    
);

parameter  IDLE      = 2'b00,
           ACK_ADD  = 2'b01,
           READ_DATA = 2'b10 ;

reg [1:0] state;

reg [31:0] reg_data;
reg [31:0] reg_addr;

always @(*) begin
     case (reg_addr)
         32'h10:  reg_data = 32'd25;  // Data for address 0x10 is 25
         32'h20:  reg_data = 32'd50;  // Data for address 0x20 is 50
         default: reg_data = 32'd0;   // Default data
     endcase
 end
     


always @(posedge ACLK or negedge ARSTn) begin
     if(!ARSTn) begin
          state <= IDLE;
          ARREADY <= 1'b0;
          RVALID  <= 1'b0;
          RDATA   <= 32'd0;
          RRESP   <= 2'b00;
          reg_addr  <= 32'd0;

     end else begin
       case(state)

          IDLE:  begin
               RVALID <=1'b0;  // intitallly data channel is not in use
                    if(ARVALID) begin
                         ARREADY<=1'b1;
                         reg_addr<= ARADDER;
                         state<=ACK_ADD;
                    end else 
                         ARREADY<=1'b0;
          end

          ACK_ADD : begin
               ARREADY<= 1'b0;
               state<=READ_DATA;
          end
          

          READ_DATA: begin
                    RVALID<=1'b1;
                    RDATA<= reg_data;
                    RRESP<=2'b00;
               
                    if(RREADY ) begin
                         state<=IDLE;
                         RVALID<=1'b0;
                    end else begin
                    state  <= READ_DATA; // Wait for RREADY
               end
            end
          
          default: begin
               state<=IDLE;
          end


     endcase
end
     
end
endmodule

`timescale 1ps/1ps

module tb_axi();

reg         ACLK;
reg         ARSTn;
reg  [31:0] ARADDER;
reg         ARVALID;
reg         RREADY;

wire        ARREADY;
wire [31:0] RDATA;
wire [1:0]  RRESP;
wire        RVALID;


axi_lite_read dut(
     .ACLK    (ACLK),
    .ARSTn   (ARSTn),
    .ARADDER  (ARADDER),
    .ARVALID (ARVALID),
    .RREADY  (RREADY),
    .ARREADY (ARREADY),
    .RDATA   (RDATA),
    .RRESP   (RRESP),
    .RVALID  (RVALID)
);

initial begin
     ACLK = 0;
     forever #5 ACLK = ~ACLK; // 100MHz clock (10ns period)
 end

 // 4. Main stimulus block
 initial begin
     // Waveform dumping at the start
     $dumpfile("axi_read_tb.vcd");
     $dumpvars(0, tb_axi);

     // Proper reset sequence
     ARSTn   <= 1'b0; // Assert active-low reset
     ARADDER  <= 32'b0;
     ARVALID <= 1'b0;
     RREADY  <= 1'b0;
     #20;
     ARSTn   <= 1'b1; // De-assert reset
     @(posedge ACLK);

     // --- Start First Transaction: Read from 0x10 ---
     $display("INFO: Starting read transaction for address 0x10");
     ARADDER  <= 32'h10;
     ARVALID <= 1'b1;
     
     // Wait for slave to be ready for the address
     @(posedge ACLK);
     while (!ARREADY) begin
         @(posedge ACLK);
     end
     
     // Address handshake complete, de-assert ARVALID
     ARVALID <= 1'b0;
     $display("INFO: Address 0x10 accepted by slave.");

     // Prepare to receive data
     RREADY <= 1'b1;

     // Wait for slave to provide valid data
     while (!RVALID) begin
         @(posedge ACLK);
     end

     // Data received, check it
     if (RDATA == 32'd25) begin
         $display("SUCCESS: Read data from 0x10 is %d", RDATA);
     end else begin
         $display("ERROR: Expected 25, but got %d", RDATA);
     end

     // De-assert RREADY and wait a cycle
     @(posedge ACLK);
     RREADY <= 1'b0;
     
     #20; // Delay between transactions

     // --- Start Second Transaction: Read from 0x20 ---
     $display("INFO: Starting read transaction for address 0x20");
     ARADDER  <= 32'h20;
     ARVALID <= 1'b1;

     @(posedge ACLK);
     while (!ARREADY) begin
         @(posedge ACLK);
     end

     ARVALID <= 1'b0;
     $display("INFO: Address 0x20 accepted by slave.");

     RREADY <= 1'b1;
     while (!RVALID) begin
         @(posedge ACLK);
     end
     
     if (RDATA == 32'd50) begin
         $display("SUCCESS: Read data from 0x20 is %d", RDATA);
     end else begin
         $display("ERROR: Expected 50, but got %d", RDATA);
     end

     @(posedge ACLK);
     RREADY <= 1'b0;
     
     #20;
     $finish;
 end



endmodule