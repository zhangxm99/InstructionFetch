module nbjProcess (
    input drive_from_front,
    input drive_from_back,
    input data_from_back,
    input free_from_mutex,
    input rst,
    input [7:0] i_firstJTableEntry_8,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_5,
    input [31:0] i_currentPc_32,
    input [35*10-1:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8,
    output [1:0] o_type,
    output o_drive_next,
    output o_free_front,
    output o_free_back,
);

    wire drive_from_arb_to_cond;
    wire[36:0] data_from_arb;
    wire free_from_cond_to_arb;

    // cArbMerge2_33b cArbMerge2_33b(.i_drive0(drive_from_front),
    //                               .i_drive1(drive_from_back),
    //                               .i_data0_33(33'b0),
    //                               .i_data1_33(data_from_back),
    //                               .i_freeNext(free_from_cond_to_arb),
    //                               .rst(rst),
    //                               .o_driveNext(drive_from_arb_to_cond),
    //                               .o_free0(o_free_front),
    //                               .o_free1(o_free_back),
    //                               .o_data_33(data_from_arb));
    //这里由于cArbMerge有问题，所以先用MutexMerge替代测试
    cMutexMerge2_37b cMutexMerge2_37b(.i_drive0(drive_from_front),
                                .i_drive1(drive_from_back),
                                .i_data0_37(37'b0),
                                .i_data1_37(data_from_back),
                                .i_freeNext(free_from_cond_to_arb),
                                .rst(rst),
                                .o_driveNext(drive_from_arb_to_cond),
                                .o_free0(o_free_front),
                                .o_free1(o_free_back),
                                .o_data_37(data_from_arb));

    wire fire_from_lastfifo;
    wire drive_cfifo;
    wire drive_clastfifo;
    wire free_from_lastfifo_to_cond;
    wire free_from_cfifo_to_cond;
    wire valid0,valid1;
    assign valid0 = data_from_arb[36] == 0?1:0;
    assign valid1 = data_from_arb[36] == 0?0:1;
    cCondFork2 cCondFork2(.i_drive(drive_from_arb_to_cond),
                          .i_freeNext0(free_from_cfifo_to_cond),
                          .i_freeNext1(free_from_lastfifo_to_cond),
                          .valid0(valid0),
                          .valid1(valid1),
                          .rst(rst),
                          .o_free(free_from_cond_to_arb),
                          .o_driveNext0(drive_cfifo),
                          .o_driveNext1(drive_clastfifo));


    wire fire_from_cfifo;
    cFifo1 cFifo(.i_drive(drive_cfifo),
                       .i_freeNext(free_from_mutex),
                       .o_free(free_from_cfifo_to_cond),
                       .o_driveNext(o_drive_next),
                       .rst(rst),
                       .o_fire_1(fire_from_cfifo));

    wire[31:0] correctPc32Wire;
    wire[2:0] correctPcIndex3Wire;
    wire errTypeWire;
    nbjProcessLogic nbjProcessLogic (
        .rst(rst),
        .i_fire(fire_from_cfifo),
        .i_firstJTableEntry_8(i_firstJTableEntry_8),
        .i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
        .i_validSize_5(i_validSize_5),
        .i_currentPc_32(i_currentPc_32),
        .i_typeAndAddressTableBus_350(i_typeAndAddressTableBus_350),
        .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
        .i_correctPc_32(correctPc32Wire),
        .i_correctPcIndex_3(correctPcIndex3Wire),
        .i_errType(errTypeWire),
        .o_nextPc_32(o_nextPc_32),
        .o_cutPosition_8(o_cutPosition_8),
        .o_type(o_type)
    );

    wire or_fire;
    wire fire_from_clastfifo;
    cLastFifo1 cLastFifo1(.i_drive(drive_clastfifo),
                        .rst(rst),
                        .o_free(free_from_lastfifo_to_cond),
                        .o_fire_1(fire_from_clastfifo));
    assign or_fire = fire_from_cfifo | fire_from_clastfifo;
    nbjCorrect nbjCorrect(
        .i_fire(or_fire),
        .rst(rst),
        .i_data_37(data_from_arb),
        .o_errType(errTypeWire),
        .o_correctPcIndex_3(correctPcIndex3Wire),
        .o_correctPc_32(correctPc32Wire)
    )
    
endmodule