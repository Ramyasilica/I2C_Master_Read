`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 02:38:53 PM
// Design Name: 
// Module Name: i2c_master_read_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module i2c_master_read_tb;

    reg clk;
    reg rst;
    reg start;

    wire scl;
    wire sda;

    wire sda_master_oe;
    reg  sda_slave_oe;

    wire [7:0] data_out;
    wire busy;

    reg [7:0] slave_data;
    reg [3:0] bit_cnt;

    // Open-drain SDA
    assign sda = (sda_master_oe || sda_slave_oe) ? 1'b0 : 1'b1;

    i2c_master_read dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(7'h50),
        .sda(sda),
        .sda_oe(sda_master_oe),
        .scl(scl),
        .data_out(data_out),
        .busy(busy)
    );

    always #5 clk = ~clk;

    // SLAVE: ACK + SEND A5
    always @(negedge scl or posedge rst) begin
        if (rst) begin
            slave_data   <= 8'hA5;
            bit_cnt      <= 7;
            sda_slave_oe <= 0;
        end else if (busy) begin

            // ACK phase
            if (dut.state == 3'd3)
                sda_slave_oe <= 1'b1; // ACK = pull low

            // READ phase
            else if (dut.state == 3'd4) begin
                sda_slave_oe <= ~slave_data[bit_cnt];
                if (bit_cnt == 0)
                    bit_cnt <= 7;
                else
                    bit_cnt <= bit_cnt - 1;
            end
            else
                sda_slave_oe <= 0;
        end
        else begin
            sda_slave_oe <= 0;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        #20 rst = 0;
        #40 start = 1;
        #10 start = 0;

        #700 $finish;
    end
endmodule


