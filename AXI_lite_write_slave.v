module axi_lite_write (
    input         ACLK,
    input         ARSTn,

// master port
    input  [31:0] AWADDR,
    input         AWVALID,
    output reg    AWREADY,

// slave port
    input  [31:0] WDATA,
    input         WVALID,
    output reg    WREADY,

//responses
    output reg        BVALID,
    input             BREADY,
    output reg  [1:0] BRESP
);

parameter IDLE  = 2'b00,
          START = 2'b01,
          DATA  = 2'b10,
          RESP  = 2'b11;

reg [1:0] state;

reg [31:0] addr_in_reg;
reg [31:0] data_in_reg;
reg [31:0] slave_register;

always @(posedge ACLK or negedge ARSTn) begin
    if (!ARSTn) begin
        state          <= IDLE;
        AWREADY        <= 0;
        WREADY         <= 0;
        BVALID         <= 0;
        BRESP          <= 2'b00;
        slave_register <= 32'd0;
    end else begin
        // Default outputs
        AWREADY <= 0;
        WREADY  <= 0;

        case (state)

            IDLE: begin
                if (AWVALID) begin
                    AWREADY     <= 1;
                    addr_in_reg <= AWADDR;
                    state       <= START;
                end
            end

            START: begin
                if (WVALID) begin
                    WREADY       <= 1;
                    data_in_reg  <= WDATA;
                    slave_register <= WDATA;
                    state        <= RESP;
                end
            end

            RESP: begin
                BVALID <= 1;
                BRESP  <= 2'b00;  // OKAY

                if (BREADY) begin
                    BVALID <= 0;
                    state  <= IDLE;
                end
            end

        endcase
    end
end

endmodule


`timescale 1ns/1ps

module tb_axi_lite_write;

reg         ACLK;
reg         ARSTn;
reg  [31:0] AWADDR;
reg         AWVALID;
reg  [31:0] WDATA;
reg         WVALID;
reg         BREADY;

wire        AWREADY;
wire        WREADY;
wire        BVALID;
wire [1:0]  BRESP;

axi_lite_write dut (
    .ACLK     (ACLK),
    .ARSTn    (ARSTn),
    .AWADDR   (AWADDR),
    .AWVALID  (AWVALID),
    .AWREADY  (AWREADY),
    .WDATA    (WDATA),
    .WVALID   (WVALID),
    .WREADY   (WREADY),
    .BVALID   (BVALID),
    .BREADY   (BREADY),
    .BRESP    (BRESP)
);

initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;   // 100MHz clock
end

initial begin
    $dumpfile("axi_write_tb.vcd");
    $dumpvars(0, tb_axi_lite_write);

    // Reset
    ARSTn   = 0;
    AWADDR  = 0;
    AWVALID = 0;
    WDATA   = 0;
    WVALID  = 0;
    BREADY  = 0;
    #20;
    ARSTn = 1;

    // WRITE 1: Write 0x1111_2222 to address 0x10
    @(posedge ACLK);
    AWADDR  <= 32'h10;
    AWVALID <= 1;
    @(posedge ACLK);
    while (!AWREADY) @(posedge ACLK);
    AWVALID <= 0;

    WDATA  <= 32'h11112222;
    WVALID <= 1;
    @(posedge ACLK);
    while (!WREADY) @(posedge ACLK);
    WVALID <= 0;

    BREADY <= 1;
    @(posedge ACLK);
    while (!BVALID) @(posedge ACLK);
    $display("BRESP = %b (expected 00)", BRESP);
    BREADY <= 0;

    #20;
    $finish;
end

endmodule
