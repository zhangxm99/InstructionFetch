module nbprocess (
    input wire[4:0] i_validSize_5,
    input wire[3:0] i_alignedInstructionNumber_4,
    input wire[31:0] i_currentPC_32,
    output wire[31:0] o_nextPc_32,
    output wire[7:0] o_cutPosition_8
);

    assign o_nextPc_32 = i_currentPC_32 + i_validSize_5;
    assign o_cutPosition_8 = i_alignedInstructionNumber_4-1;
    
endmodule