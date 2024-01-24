module bProcessLogic (
    input rst,
    input drive_from_back,
    input [32:0] data_from_back,
    input drive_from_front,
    input free_from_mutex,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_4,
    input [8*10-1:0] i_jumpGatherTableBus_80,
    input [349:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    input [31:0] i_currentPc_32,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8,
    output o_free_front,
    output o_free_back,
    output drive_next
);
    wire[9*20-1:0] globalHistoryRegister_180Wire;
    wire[8*9*228-1:0] weightTableWire;
    wire[31:0] correctPCWire;
    wire[2:0] counter_3Wire;
    wire[7:0] pendingB_8Wire;
    wire[7:0] errWeightPos_8Wire;
    wire[8*9-1:0] newWeightsWire;
    wire[7:0] newPendingB_8Wire;
    wire[9*4-1:0] newGHREntry_36Wire;
    wire[2:0] newpassBNum_3Wire;

    wire drive_from_arb_to_cond;
    wire[32:0] data_from_arb;
    wire free_from_cond_to_arb;

    cArbMerge2_33b cArbMerge2_33b(.i_drive0(drive_from_front),
                                  .i_drive1(drive_from_back),
                                  .i_data0_33(33'b0),
                                  .i_data1_33(data_from_back),
                                  .i_freeNext(free_from_cond_to_arb),
                                  .rst(rst),
                                  .o_driveNext(drive_from_arb_to_cond),
                                  .o_free0(o_free_front),
                                  .o_free1(o_free_back),
                                  .o_data_33(data_from_arb));

    wire fire_from_lastfifo;
    wire drive_cfifo;
    wire drive_clastfifo;
    wire free_from_cfifo_to_cond;
    wire free_from_lastfifo_to_cond;
    assign valid0 = data_from_arb == 33'b0?1:0;
    assign valid1 = data_from_arb == 33'b0?0:1;
    cCondFork2 cCondFork2(.i_drive(drive_from_arb_to_cond),
                          .i_freeNext0(free_from_cfifo_to_cond),
                          .i_freeNext1(free_from_lastfifo_to_cond),
                          .valid0(valid0),
                          .valid1(valid1),
                          .rst(rst),
                          .o_free(free_from_cond_to_arb),
                          .o_driveNext0(drive_cfifo),
                          .o_driveNext1(drive_clastfifo));


    wire fire_SRAM1;
    wire free_from_cfifo2nd_to_cfifo1st;
    wire drive_from_cfifo1st_to_cfifo2nd;
    wire free_from_cfifo1st_to_cond;
    cFifo1 cFifo_first(.i_drive(drive_cfifo),
                       .i_freeNext(free_from_cfifo2nd_to_cfifo1st),
                       .o_free(free_from_cfifo1st_to_cond),
                       .o_driveNext(drive_from_cfifo1st_to_cfifo2nd),
                       .rst(rst),
                       .o_fire_1(fire_SRAM1));

    wire[3:0] consecutiveBNum_4Wire;
    wire[8*4-1:0] weightsAddr;
    checkNum checkNum(.i_jumpGatherTableBus_80(i_jumpGatherTableBus_80),
                      .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
                      .o_consecutiveBNum_4(consecutiveBNum_4Wire),
                      .o_weightsAddr_32(weightsAddr));

    wire[8*9*4-1:0] weights_288Wire;
    wire gotErrWire;
    assign or_fire = fire_read_errWeight | fire_write_errWeight | fire_SRAM1;
    weightTable weightTable(.i_fire(or_fire),
                            .rst(rst),
                            .i_weightsAddr_32(weightsAddr),
                            .i_globalHistoryRegister_180(globalHistoryRegister_180Wire),
                            .i_gotErr(gotErrWire),
                            .o_weights_288(weights_288Wire));

    bPredictAndLearning bPredictAndLearning(.i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
                                            .i_validSize_4(i_validSize_4),
                                            .i_jumpGatherTableBus_80(i_jumpGatherTableBus_80),
                                            .i_alignedInstructionTableBus_640(i_alignedInstructionTableBus_640),
                                            .i_typeAndAddressTableBus_350(i_typeAndAddressTableBus_350),
                                            .i_currentPc_32(i_currentPc_32),
                                            .i_globalHistoryRegister_180(globalHistoryRegister_180Wire),
                                            .i_consecutiveBNum_4(consecutiveBNum_4Wire),
                                            .i_weights_288(weights_288Wire),
                                            .i_correctPC(correctPCWire),
                                            .i_counter_3(counter_3Wire),
                                            .i_pendingB_8(pendingB_8Wire),
                                            .o_newGHREntry_36(newGHREntry_36Wire),
                                            .o_newPendingB_8(newPendingB_8Wire),
                                            .o_newpassBNum_3(newpassBNum_3Wire),
                                            .o_getErr(gotErrWire),
                                            .o_nextPc_32(o_nextPc_32),
                                            .o_cutPosition_8(o_cutPosition_8));

    wire fire_from_cfifo2nd;
    wire fire_ghr_pendingB;
    wire fire_read_errWeight;
    wire fire_write_errWeight;
    cFifo3 cfifo_second(.i_drive(drive_from_cfifo1st_to_cfifo2nd),
                       .i_freeNext(free_from_mutex),
                       .o_free(free_from_cfifo2nd_to_cfifo1st),
                       .o_driveNext(drive_next),
                       .rst(rst),
                       .o_fire_1(fire_ghr_pendingB),
                       .o_fire_2(fire_read_errWeight),
                       .o_fire_3(fire_write_errWeight));

    ghrAndPendingB ghrAndPendingB(.fire(fire_from_cfifo2nd),
                                  .rst(rst),
                                  .i_newPendingB_8(newPendingB_8Wire),
                                  .i_passBNum_3(newpassBNum_3Wire),
                                  .i_newGHREntry_36(newGHREntry_36Wire),
                                  .o_pendingB_8(pendingB_8Wire),
                                  .o_globalHistoryRegister_180(globalHistoryRegister_180Wire));

    wire fire_from_clastfifo;
    assign fire_from_cfifo2nd_or_clastfifo = fire_from_clastfifo | fire_from_cfifo2nd;
    bcorrect bcorrect(.fire(fire_from_cfifo2nd_or_clastfifo),
                      .rst(rst),
                      .i_data(data_from_back),
                      .o_counter(counter_3Wire),
                      .o_correctpc(correctPCWire));

    cLastFifo1 cLastFifo1(.i_drive(drive_clastfifo),
                          .rst(rst),
                          .o_free(free_from_lastfifo_to_cond),
                          .o_fire_1(fire_from_clastfifo));






endmodule