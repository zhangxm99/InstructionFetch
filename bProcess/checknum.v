`define B 3'd1

module checkNum (
    input [8*10-1:0] i_jumpGatherTableBus_80,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    output [3:0] o_consecutiveBNum_4,
    output [8*4-1:0] o_weightsAddr_32
);

    //跳转汇集表,每个表项由5bits num_offset、3bits type组成
    wire[7:0] w_jumpGatherTable_8[9:0];
    //对齐指令表，每个表项有32bits instructions和32bits accurate_addr
    wire[63:0] w_alignedInstructionTable_64[9:0];
    genvar i;
    generate
        for(i = 0;i < 10;i = i+1)begin
            assign w_alignedInstructionTable_64[i] = i_alignedInstructionTableBus_640[i*64+:64];
            assign w_jumpGatherTable_8[i] = i_jumpGatherTableBus_80[i*8 +: 8];
        end
        for(i = 0;i < 4;i = i+1)begin
            assign o_weightsAddr_32[i*8 +: 8] = w_alignedInstructionTable_64[w_jumpGatherTable_8[i][3+:5]][32+:32] % 228;
        end
    endgenerate

    assign o_consecutiveBNum_4 = (w_jumpGatherTable_8[0][0+:3] == `B?(w_jumpGatherTable_8[1][0+:3] == `B?(w_jumpGatherTable_8[2][0+:3] == `B?(w_jumpGatherTable_8[3][0+:3] == `B?4:3):2):1):0);

endmodule