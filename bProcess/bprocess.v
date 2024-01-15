//当前版本的设计可优化之处：
//目前是如果前面几个B都不跳了，就算后面找到了非B的跳转，
//也只是把pc设置成那个非B跳转的位置，在下一次取指的时候进行处理
//这样方便编码，但整整慢了一轮，后续考虑优化
`timescale 1ns / 1ps

`define NORMAL 3'd0
`define B 3'd1

module bPredictAndLearning(
    input wire[3:0] i_alignedInstructionNumber_4,
    input wire[4:0] i_validSize_4,
    input wire[19*10-1:0] i_jumpGatherTableBus_190,
    input wire[349:0] i_typeAndAddressTableBus_350,
    input wire[31:0] i_currentPc_32,
    input wire[33*20-1:0] i_globalHistoryRegister_660,
    input wire[8*9*228-1:0] i_weightTable_16416,
    input wire[31:0] i_correctPC,
    input wire[2:0] i_counter_3,
    input wire[7:0] i_pendingB_8,
    output wire[7:0] o_errWeightPos_8,
    output wire[8*9-1:0] o_newWeights,
    output wire[3:0] o_newPendingB_3,
    output wire[33*4-1:0] o_newGHREntry_132,
    output wire[2:0] o_passBNum_3,
    output wire[2:0] o_counter_3,
    output wire[31:0] o_clearPC,
    output wire[31:0] o_nextPc_32,
    output wire[7:0] o_cutPosition_8
    );
    //跳转汇集表,每个表项由8bits num_offset、8bits accurate_offset和3bits type组成
    wire[18:0] w_jumpGatherTable_19[9:0];
    //类型与地址表，每个表项由32bits address和3bits type组成
    wire[34:0] w_typeAndAddressTable_35[0:9];
    //有效指令汇集表
    wire[31:0] w_validInstruction_32[9:0];
    //权重表
    wire[9*8-1:0] r_weightTable_9[227:0];

    //生成各表
    genvar i;
    generate
        for(i = 0;i < 10;i = i+1)begin
            assign w_jumpGatherTable_19[i] = i_jumpGatherTableBus_190[i*19 +: 19];
            assign w_typeAndAddressTable_35[i] = i_typeAndAddressTableBus_350[i*35 +: 35];
        end
        for(i = 0;i < 228;i = i+1)
            assign r_weightTable_9[i] = i_weightTable_16416[i*72+:72];
    endgenerate

    //连续B型指令的判定
    wire[2:0] counter_3;
    generate
        //算法参考：https://stackoverflow.com/questions/38230450/first-non-zero-element-encoder-in-verilog
        wire[3:0] b_tmp[10:0];
        assign b_tmp[0] = 0;
        for(i = 0;i < 10;i = i+1) begin
            assign b_tmp[i+1] = w_jumpGatherTable_19[i][0+:3] == `B?i:b_tmp[i];
        end
        assign counter_3 = b_tmp[10]+1;
    endgenerate

    //同步预测
    generate
        wire[3:0] IndexOfWeightTable[9:0];
        wire[7:0] mul[8:0];
        wire[10:0] sum[3:0];
        wire res[3:0];
        for (i = 0;i < 4;i = i+1) begin
            assign IndexOfWeightTable[i] = (w_jumpGatherTable_19[i][3+:10] + i_currentPc_32) % 228;
            
            genvar j;
            for(j = 0;j < 8;j = j+1) begin
                assign mul[j] = i_globalHistoryRegister_660[j*33] == 1?r_weightTable_9[IndexOfWeightTable[i]][j*8+:8]:0;
            end
            assign sum[i] = mul[0]+mul[1]+mul[2]+mul[3]+mul[4]+mul[5]+mul[6]+mul[7] + r_weightTable_9[IndexOfWeightTable[i]][8*8+:8];
            assign res[i] = sum[i] > 0?1:0;
        end

        //找到第一个跳转指令位置
        wire[3:0] j_tmp[4:0];
        //算法思路：从最后一位向前依次看，如果出现了想要的情况，就写入当前的索引，这样就能保证第0位要不然为最先出现的，要不然就是无效值
        assign j_tmp[4] = 15;
        for(i = 3;i >= 0;i = i-1)begin
            assign j_tmp[i] = res[i] == 1?i:j_tmp[i+1];
        end
        assign firstJPos = j_tmp[0];
    endgenerate

    //标记是否预测值中有判定跳转的
    assign predictGotJ = firstJPos < counter_3?1:0;
    //存储从头到第一个预测为跳，共有几个B，如果都预测不跳，就是B指令个数
    assign passBNum_3 = predictGotJ?(firstJPos+1):counter_3;

    //错误检查与学习逻辑
    assign o_counter_3 = 0;
    assign o_clearPC = 0;
    assign gotErr = i_correctPC == 0? 0:1;
    assign o_passBNum_3 = gotErr?-1:passBNum_3;
    assign errPos = i_pendingB_8-i_counter_3;
    assign o_newPendingB_3 = gotErr?errPos:errPos+o_passBNum_3;
    
    assign o_errWeightPos_8 = gotErr?i_globalHistoryRegister_660[(errPos-1)*33+1+:32] % 228:-1;
    assign correctRes = ~i_globalHistoryRegister_660[(errPos-1)*33];

    generate
        for(i = 0;i < 8;i = i+1)begin
            assign o_newWeights[i*8+:8] = r_weightTable_9[o_errWeightPos_8][i*8] + (i_globalHistoryRegister_660[(errPos + i)*33] == correctRes?1:-1);
        end
        assign o_newWeights[8*8+:8] = r_weightTable_9[o_errWeightPos_8][8*8+:8] + (correctRes == 1?1:-1);
    endgenerate

    wire[33*4-1:0] tmpEntry;
    generate
        for(i = 3;i >= 0;i=i-1)begin
            assign tmpEntry[i*33+1+:32] = w_typeAndAddressTable_35[w_jumpGatherTable_19[3-i][11+:8]][3+:32];
            assign tmpEntry[i*33] = 0;
        end
        assign o_newGHREntry_132 = gotErr?0:((tmpEntry>>(33*(4-o_passBNum_3))) | (predictGotJ ? 1:0));
    endgenerate

    //找到B后面第一个非B跳转，如果预测所有B都不跳就从这条指令跳了
    wire[3:0] findJ_tmp[10:0];
    wire[3:0] afterBFirstJ;
    assign findJ_tmp[10] = 0;
    generate
        for(i = 9;i >= 0;i = i-1)begin
            assign findJ_tmp[i] = w_jumpGatherTable_19[i][0+:3] != `B && w_jumpGatherTable_19[i][0+:3] != `NORMAL?i:findJ_tmp[i+1];
        end
        assign afterBFirstJ = findJ_tmp[0];
    endgenerate

    assign o_nextPc_32 = gotErr?
    i_correctPC:
    predictGotJ ? 
    w_typeAndAddressTable_35[w_jumpGatherTable_19[firstJPos][11+:8]][3+:32]:
    afterBFirstJ == 0?
    i_currentPc_32+i_validSize_4:
    w_typeAndAddressTable_35[w_jumpGatherTable_19[afterBFirstJ][11+:8]][3+:32];
    
    assign o_cutPosition_8 = gotErr?
    -1:
    predictGotJ ? 
    w_jumpGatherTable_19[firstJPos][11+:8]:
    afterBFirstJ == 0?
    i_alignedInstructionNumber_4-1:
    w_jumpGatherTable_19[afterBFirstJ][11+:8];

endmodule

