module nbjCorrect (
    input i_fire,
    input rst,
    input [35:0] i_data_37,
    output reg o_type,
    output reg [2:0] o_correctPcIndex_3,
    output reg [31:0] o_correctPc_32
);
    always @(posedge i_fire or negedge rst) begin
        if(!rst)begin
            o_type <= 0;
            o_correctPc_32 <= 32'b0;
            o_correctPcIndex_3 <= 3'b0;
        end
        else begin
            o_correctPc_32 <= i_data_37[0+:32];
            o_correctPcIndex_3 <= i_data_37[32+:3];
            o_type <= i_data_37[35];
        end
    end
endmodule