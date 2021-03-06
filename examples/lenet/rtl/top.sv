module lenet (
    input logic clk,
    input logic rstn,
    input logic valid,
    input logic [400-1:0] input_act,
    output logic [256-1:0] output_act,
    output logic ready
);

logic [400-1:0] input_act_ff;
always_ff @(posedge clk or negedge rstn) begin
    if (rstn == 0) begin
        input_act_ff <= '0;
        ready <= '0;
    end
    else begin
        input_act_ff <= input_act;
        ready <= valid;
    end
end

logic conv1_buf_valid;
logic [400-1:0] conv1_buf_act;
buffer_main #(
    .KER_SIZE(5),
    .BITWIDTH(16),
    .INPUT_FMAPS(1),
    .STRIDE(1),
    .NW(32),
    .AW(6)
) conv1_buf_inst (
    .clk(clk),
    .rstn(rstn),
    .valid(valid_ff),
    .flush(flush_ff),
    .input_act(input_act_ff),
    .output_act(conv1_buf_act),
    .ready(conv1_buf_valid)
);

logic [96-1:0] conv1_act;
conv1 conv1_inst (
    .clk (clk),
    .rstn (rstn),
    .valid (conv1_buf_valid),
    .input_act (conv1_buf_act),
    .output_act (conv1_act),
    .ready (conv1_valid),
);

logic pool1_buf_valid;
logic [384-1:0] pool1_buf_act;
buffer_main #(
    .KER_SIZE(2),
    .BITWIDTH(16),
    .INPUT_FMAPS(6),
    .STRIDE(2),
    .NW(28),
    .AW(5)
) pool1_buf_inst (
    .clk(clk),
    .rstn(rstn),
    .valid(conv1_valid),
    .flush(flush_ff),
    .input_act(conv1_act),
    .output_act(pool1_buf_act),
    .ready(pool1_buf_valid)
);

logic [96-1:0] pool1_act;
max_pool_2d #(
    .NBITS (16),
    .NFMAPS (6),
    .KERSIZE (2)
) pool1_instance (
    .input_act (pool1_buf_act),
    .output_act (pool1_act)
);

logic conv2_buf_valid;
logic [2400-1:0] conv2_buf_act;
buffer_main #(
    .KER_SIZE(5),
    .BITWIDTH(16),
    .INPUT_FMAPS(6),
    .STRIDE(1),
    .NW(14),
    .AW(4)
) conv2_buf_inst (
    .clk(clk),
    .rstn(rstn),
    .valid(pool1_valid),
    .flush(flush_ff),
    .input_act(pool1_act),
    .output_act(conv2_buf_act),
    .ready(conv2_buf_valid)
);

logic [256-1:0] conv2_act;
conv2 conv2_inst (
    .clk (clk),
    .rstn (rstn),
    .valid (conv2_buf_valid),
    .input_act (conv2_buf_act),
    .output_act (conv2_act),
    .ready (conv2_valid),
);

logic pool2_buf_valid;
logic [1024-1:0] pool2_buf_act;
buffer_main #(
    .KER_SIZE(2),
    .BITWIDTH(16),
    .INPUT_FMAPS(16),
    .STRIDE(2),
    .NW(10),
    .AW(4)
) pool2_buf_inst (
    .clk(clk),
    .rstn(rstn),
    .valid(conv2_valid),
    .flush(flush_ff),
    .input_act(conv2_act),
    .output_act(pool2_buf_act),
    .ready(pool2_buf_valid)
);

logic [256-1:0] pool2_act;
max_pool_2d #(
    .NBITS (16),
    .NFMAPS (16),
    .KERSIZE (2)
) pool2_instance (
    .input_act (pool2_buf_act),
    .output_act (pool2_act)
);

always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        output_act <= '0;
        ready      <= '0;
        end
    else begin
        output_act <= pool2_act;
        ready      <= pool2_valid;
    end
end
endmodule