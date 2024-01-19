module bProcessLogic (
    input drive_from_back,
    input [32:0] data_from_back,
    input drive_from_prev,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_4,
    input [19*10-1:0] i_jumpGatherTableBus_190,
    input [349:0] i_typeAndAddressTableBus_350,
    input [31:0] i_currentPc_32,
    input rst,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8,
    output o_free_prev,
    output o_free_back
);

    wire[33*20-1:0] globalHistoryRegister_660Wire;
    wire[8*9*228-1:0] weightTableWire;
    wire[31:0] correctPCWire;
    wire[2:0] counter_3Wire;
    wire[7:0] pendingB_8Wire;
    wire[7:0] errWeightPos_8Wire;
    wire[8*9-1:0] newWeightsWire;
    wire[7:0] newPendingB_8Wire;
    wire[33*4-1:0] newGHREntry_132Wire;
    wire[2:0] newpassBNum_3Wire;
    wire[31:0] clearPCWire;
    wire newcounter_3Wire;

    wire drive_from_arb_to_cond;
    wire[32:0] data_from_arb;
    wire free_from_cond_to_arb;
    cArbMerge2_33b cArbMerge2_33b(.i_drive0(drive_from_prev),
                                  .i_drive1(drive_from_back),
                                  .i_data0_33({newcounter_3Wire,clearPCWire}),
                                  .i_data1_33(data_from_back),
                                  .i_freeNext(free_from_cond_to_arb),
                                  .rst(rst),
                                  .o_driveNext(drive_from_arb_to_cond),
                                  .o_free0(o_free_prev),
                                  .o_free1(o_free_back),
                                  .o_data_33(data_from_arb));
    wire fire_from_lastfifo;
    wire drive_front;
    wire drive_back;
    wire free_from_Front_lastfifo_to_cond;
    wire free_from_Back_lastfifo_to_cond;
    assign choose_way = data_from_arb == 0?1:0;
    cCondFork2 cCondFork2(.i_drive(drive_from_arb_to_cond),
                          .i_freeNext0(free_from_Front_lastfifo_to_cond),
                          .i_freeNext1(free_from_Back_lastfifo_to_cond),
                          .valid0(choose_way),
                          .valid1(choose_way),
                          .rst(rst),
                          .o_free(free_from_cond_to_arb),
                          .o_driveNext0(drive_front),
                          .o_driveNext1(drive_back));

    wire drive_from_cond_to_front_lastfifo;
    wire drive_from_cond_to_back_lastfifo;
    wire fire_from_front_lastfifo;
    wire fire_from_back_lastfifo;
    cLastFifo1 fire_for_front(.i_drive(drive_from_cond_to_front_lastfifo),
               .rst(rst),
               .o_free(free_from_Front_lastfifo_to_cond),
               .o_fire_1(fire_from_front_lastfifo));
    
    cLastFifo1 fire_for_back(.i_drive(drive_from_cond_to_back_lastfifo),
               .rst(rst),
               .o_free(free_from_Back_lastfifo_to_cond),
               .o_fire_1(fire_from_back_lastfifo));

    btables btables(.fire(fire_from_front_lastfifo),
                    .rst(rst),
                    .i_newPendingB_8(newPendingB_8Wire),
                    .i_passBNum_3(newpassBNum_3Wire),
                    .i_errWeightPos_8(errWeightPos_8Wire),
                    .i_newWeights_72(newWeightsWire),
                    .i_newGHREntry_132(newGHREntry_132Wire),
                    .o_pendingB_8(pendingB_8Wire),
                    .o_globalHistoryRegister_660(globalHistoryRegister_660Wire),
                    .o_weightTable_16416(weightTableWire));

    assign fire_or = fire_from_front_lastfifo|fire_from_back_lastfifo;
    bcorrect bcorrect(.fire(fire_or),
                      .i_data(data_from_arb),
                      .o_counter(counter_3Wire),
                      .o_correctpc(correctPCWire));

    bPredictAndLearning bPredictAndLearning(.i_alignedInstructionNumber_4(i_alignedInstructionNumber_4),
                        .i_validSize_4(i_validSize_4),
                        .i_jumpGatherTableBus_190(i_jumpGatherTableBus_190),
                        .i_typeAndAddressTableBus_350(i_typeAndAddressTableBus_350),
                        .i_currentPc_32(i_currentPc_32),
                        .i_globalHistoryRegister_660(globalHistoryRegister_660Wire),
                        .i_weightTable_16416(weightTableWire),
                        .i_correctPC(correctPCWire),
                        .i_counter_3(counter_3Wire),
                        .i_pendingB_8(pendingB_8Wire),
                        .o_errWeightPos_8(errWeightPos_8Wire),
                        .o_newWeights(newWeightsWire),
                        .o_newPendingB_3(newPendingB_8Wire),
                        .o_newGHREntry_132(newGHREntry_132Wire),
                        .o_newpassBNum_3(newpassBNum_3Wire),
                        .o_newcounter_3(newcounter_3Wire),
                        .o_clearPC(clearPCWire),
                        .o_nextPc_32(o_nextPc_32),
                        .o_cutPosition_8(o_cutPosition_8));
    
endmodule