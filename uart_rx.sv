`include "clock_mul.sv"
// commented out to compile verilog command 

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// STATES: State of the state machine
localparam DATA_BITS = 8;
localparam 
    INIT = 0, 
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

// CLOCK MULTIPLIER: Instantiate the clock multiplier
wire uart_clk;
clock_mul #(
    .SRC_FREQ(SRC_FREQ),
    .OUT_FREQ(BAUDRATE)
) uart_clock (
    .src_clk(clk),
    .out_clk(uart_clk)
);

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.
reg rx_ready_uart = 1'b0;
reg rx_ready_sync_0 = 1'b0;
reg rx_ready_sync_1 = 1'b0;

always @(posedge clk) begin
    rx_ready_sync_0 <= rx_ready_uart;
    rx_ready_sync_1 <= rx_ready_sync_0;
    rx_ready <= rx_ready_sync_0 & ~rx_ready_sync_1;
end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal
integer state = INIT;
integer bit_index = 0;
reg [7:0] rx_shift = 8'b0;

always @(posedge uart_clk) begin
    rx_ready_uart <= 1'b0;

    case (state)
        INIT: begin
            rx_data <= 8'b0;
            rx_shift <= 8'b0;
            bit_index <= 0;
            state <= IDLE;
        end

        IDLE: begin
            bit_index <= 0;
            if (rx == 1'b0) begin
                state <= RX_DATA;
            end
        end

        RX_DATA: begin
            rx_shift[bit_index] <= rx;
            if (bit_index < DATA_BITS - 1) begin
                bit_index <= bit_index + 1;
            end
            else begin
                bit_index <= 0;
                state <= STOP;
            end
        end

        STOP: begin
            if (rx == 1'b1) begin
                rx_data <= rx_shift;
                rx_ready_uart <= 1'b1;
            end
            state <= IDLE;
        end
    endcase
end

endmodule