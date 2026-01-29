`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 02:38:15 PM
// Design Name: 
// Module Name: i2c_master_read
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
   
    module i2c_master_read (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [6:0] slave_addr,

    input  wire sda,
    output reg  sda_oe,
    output reg  scl,

    output reg [7:0] data_out,
    output reg busy
);

    // FSM states
    parameter IDLE  = 3'd0,
              START = 3'd1,
              ADDR  = 3'd2,
              ACK   = 3'd3,
              READ  = 3'd4,
              NACK  = 3'd5,
              STOP  = 3'd6;

    reg [2:0] state;
    reg [7:0] shift;
    reg [3:0] bit_cnt;

    // STOP helper
    reg stop_phase;

    // -----------------------------
    // SCL generator (unchanged)
    // -----------------------------
    reg [3:0] div;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div <= 0;
            scl <= 1;
        end else begin
            div <= div + 1;
            if (div == 4'd1) begin
                scl <= ~scl;
                div <= 0;
            end
        end
    end

    // -----------------------------
    // SCL rising edge detect
    // -----------------------------
    reg scl_d;
    wire scl_rise;

    always @(posedge clk) scl_d <= scl;
    assign scl_rise = (scl == 1'b1 && scl_d == 1'b0);

    // -----------------------------
    // FSM
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            sda_oe     <= 0;
            busy       <= 0;
            bit_cnt    <= 0;
            shift      <= 0;
            data_out   <= 0;
            stop_phase <= 0;
        end else begin
            case (state)

                IDLE: begin
                    busy   <= 0;
                    sda_oe <= 0;
                    if (start) begin
                        busy  <= 1;
                        state <= START;
                    end
                end

                START: begin
                    if (scl == 1) begin
                        sda_oe  <= 1; // SDA low → START
                        shift   <= {slave_addr, 1'b1}; // read
                        bit_cnt <= 7;
                        state   <= ADDR;
                    end
                end

                ADDR: begin
                    if (scl == 0)
                        sda_oe <= ~shift[bit_cnt];

                    if (scl_rise) begin
                        if (bit_cnt == 0)
                            state <= ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                ACK: begin
                    sda_oe <= 0; // release SDA → slave ACK
                    if (scl_rise) begin
                        bit_cnt <= 7;
                        state   <= READ;
                    end
                end

                READ: begin
                    if (scl_rise) begin
                        data_out[bit_cnt] <= sda;
                        if (bit_cnt == 0)
                            state <= NACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                NACK: begin
                    sda_oe <= 0; // NACK = SDA high
                    if (scl_rise)
                        state <= STOP;
                end

                // ✅ CORRECT STOP LOGIC
                STOP: begin
                    busy <= 1;

                    // Phase 1: force SDA low while SCL low
                    if (!stop_phase) begin
                        if (scl == 0) begin
                            sda_oe     <= 1; // SDA low
                            stop_phase <= 1;
                        end
                    end
                    // Phase 2: release SDA on SCL rising edge
                    else begin
                        if (scl_rise) begin
                            sda_oe     <= 0; // SDA 0 → 1 while SCL=1
                            busy       <= 0;
                            stop_phase <= 0;
                            state      <= IDLE;
                        end
                    end
                end

            endcase
        end
    end
endmodule
