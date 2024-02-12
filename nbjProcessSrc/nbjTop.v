module nbjTop (
    input drive_from_front,
    input drive_from_back,
    input data_from_back,
    input rst,
    input [7:0] i_firstJTableEntry_8,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_5,
    input [31:0] i_currentPc_32,
    input [35*10-1:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    input [31:0] i_correctPc_32,
    input [2:0] i_correctPcIndex_3,
    input i_type,
    output clear,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8
);


    
endmodule