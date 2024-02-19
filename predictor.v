module predictor (
    input rst,
    input i_njb,
    input i_normal,
    input i_b,
    input i_freeTheQueue,
    input i_dataFromBackUpReady,
    input [36:0] i_dataFromBackUp_37,
    input i_dataFromBackDownReady,
    input [41:0] i_dataFromBackDown_42,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_5,
    input [31:0] i_currentPc_32,
    input [8*10-1:0] i_jumpGatherTableBus_80,
    input [349:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    output [7:0] o_room_8,
    output [31:0] o_nextPc_32,
    output o_PCAndInstrReady,
    output [255:0] o_PCAndInstr_256,
    output o_dataForBackReady,
    output [267:0] o_dataForBack_268,
    output o_freeCondFromNbj,
    output o_freeCondFromNormal,
    output o_freeCondFromB,
    output o_freeDataFromBackUp,
    output o_freeDataFromBackDown
);

    wire[31:0] nextPcWireFromnbj_32;
    wire[7:0] cutPositionWireFromnbj_8;
    wire drive_from_nbj_to_mutex;
    wire free_from_mutex_to_nbj;
    wire type_from_nbj;
    nbjProcess nbjProcess(
        .drive_from_front(i_njb),
        .drive_from_back(i_dataFromBackUpReady),
        .data_from_back(i_dataFromBackUp_37),
        .free_from_mutex(free_from_mutex_to_nbj),
        .rst(rst),
        .i_firstJTableEntry_8(i_jumpGatherTableBus_80[7:0]),
        .i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
        .i_validSize_5(i_validSize_5),
        .i_currentPc_32(i_currentPc_32),
        .i_typeAndAddressTableBus_350(i_typeAndAddressTableBus_350),
        .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
        .o_nextPc_32(nextPcWireFromnbj_32),
        .o_cutPosition_8(cutPositionWireFromnbj_8),
        .o_type(type_from_nbj),
        .o_drive_next(drive_from_nbj_to_mutex),
        .o_free_front(o_freeCondFromNbj),
        .o_free_back(o_freeDataFromBackUp)
    );

    wire[31:0] nextPcWireFromNormal_32;
    wire[7:0] cutPositionWireFromNormal_8;
    normalProcess normalProcess (
        .i_validSize_5(i_validSize_5),
        .i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
        .i_currentPc_32(i_currentPc_32),
        .o_nextPc_32(nextPcWireFromNormal_32),
        .o_cutPosition_8(cutPositionWireFromNormal_8)
    );

    wire[31:0] nextPcWireFromb_32;
    wire[7:0] cutPositionWireFromb_8;
    wire drive_from_b_to_mutex;
    wire free_from_mutex_to_b;
    wire[2:0] firstJPos_3;
    bProcess bProcess (
        .rst(rst),
        .drive_from_back(i_dataFromBackDownReady),
        .data_from_back(i_dataFromBackDown_42),
        .drive_from_front(i_b),
        .free_from_mutex(free_from_mutex_to_b),
        .i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
        .i_validSize_5(i_validSize_5),
        .i_jumpGatherTableBus_80(i_jumpGatherTableBus_80),
        .i_typeAndAddressTableBus_350(i_typeAndAddressTableBus_350),
        .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
        .i_currentPc_32(i_currentPc_32),
        .o_nextPc_32(nextPcWireFromb_32),
        .o_cutPosition_8(cutPositionWireFromb_8),
        .o_firstJPos_3(firstJPos_3),
        .o_free_front(o_freeCondFromB),
        .o_free_back(o_freeDataFromBackDown),
        .drive_next(drive_from_b_to_mutex)
    );

    //输入mutexMerge的每一路数据分布为：32位predictAddr、3位firstJPos、3位i_type、8位cutPosition
    wire free_from_iQueue_to_mutex;
    wire drive_from_mutex_to_iQueue;
    wire [45:0] data_from_mutex_to_iQueue;
    cMutexMerge3_46b cMutexMerge3_46b(
        .i_drive0(drive_from_nbj_to_mutex),
        .i_drive1(i_normal),
        .i_drive2(drive_from_b_to_mutex),
        .i_data0_46({nextPcWireFromnbj_32,3'b0,type_from_nbj,cutPositionWireFromnbj_8}),
        .i_data1_46({nextPcWireFromNormal_32,3'b0,3'b0,cutPositionWireFromNormal_8}),
        .i_data2_46({nextPcWireFromb_32,firstJPos_3,3'b1,cutPositionWireFromb_8}),
        .i_freeNext(free_from_iQueue_to_mutex),
        .rst(rst),
        .o_driveNext(drive_from_mutex_to_iQueue),
        .o_free0(free_from_mutex_to_nbj),
        .o_free1(o_freeCondFromNormal),
        .o_free2(free_from_mutex_to_b),
        .o_data_46(data_from_mutex_to_iQueue)
    );

    wire drive_from_iQueue;
    assign o_PCAndInstrReady = drive_from_iQueue;
    assign o_dataForBackReady = drive_from_iQueue;
    iQueue iQueue(
        .i_drive(drive_from_mutex_to_iQueue),
        .rst(rst),
        .i_freeNext(i_freeTheQueue),
        .i_cutPosition_8(data_from_mutex_to_iQueue[7:0]),
        .i_type_3(data_from_mutex_to_iQueue[8+:3]),
        .i_firstJPos_3(data_from_mutex_to_iQueue[11+:3]),
        .i_predictAddr_32(data_from_mutex_to_iQueue[14+:32]),
        .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
        .i_first4EntryofJumpGatherTable(i_jumpGatherTableBus_80[31:0]),
        .o_room_8(o_room_8),
        .o_PCAndInstr_256(o_PCAndInstr_256),
        .o_dataForBack_268(o_dataForBack_268),
        .o_driveNext(drive_from_iQueue),
        .o_free(free_from_iQueue_to_mutex)
    );
    
endmodule