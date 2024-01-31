//当前版本的设计可优化之处：
//目前是如果前面几个B都不跳了，就算后面找到了非B的跳转，
//也只是把pc设置成那个非B跳转的位置，在下一次取指的时候进行处理
//这样方便编码，但整整慢了一轮，后续考虑优化
`define B 3'd1
`define NORMAL 3'd0

module bPredictAndLearning (
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_4,
    input [31:0] i_currentPc_32,
    input [8*10-1:0] i_jumpGatherTableBus_80,
    input [349:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    input [19:0] i_globalHistoryRegister_20,
    input [3:0] i_consecutiveBNum_4,
    input [8*9*4-1:0] i_weights_288,
    input [31:0] i_correctPC,
    input [2:0] i_counter_3,
    input [7:0] i_pendingB_8,
    output o_predictGotJ,
    output [7:0] o_newPendingB_8,
    output [2:0] o_passBNum_3,
    output o_gotErr,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8
);

    //跳转汇集表,每个表项由5bits num_offset、3bits type组成
    wire[7:0] w_jumpGatherTable_8[9:0];
    //对齐指令表，每个表项有32bits instructions和32bits accurate_addr
    wire[63:0] w_alignedInstructionTable_64[9:0];
    //类型与地址表，每个表项由32bits address和3bits type组成
    wire[34:0] w_typeAndAddressTable_35[9:0];
    genvar i;
    generate
        for(i = 0;i < 10;i = i+1)begin
            assign w_alignedInstructionTable_64[i] = i_alignedInstructionTableBus_640[i*64+:64];
            assign w_jumpGatherTable_8[i] = i_jumpGatherTableBus_80[i*8 +: 8];
            assign w_typeAndAddressTable_35[i] = i_typeAndAddressTableBus_350[i*35 +: 35];
        end
    endgenerate

    generate
        wire[8*8-1:0] mul[3:0];
        wire[10:0] sum[3:0];
        wire res[3:0];
        for (i = 0;i < 4;i = i+1) begin
            genvar j;
            for(j = 0;j < 8;j = j+1) begin
                if(j < i)
                    assign mul[i][j*8+:8] = 0;
                else
                    assign mul[i][j*8+:8] = i_globalHistoryRegister_20[j] == 1?i_weights_288[i*72+j*8+:8]:0;
            end
            assign sum[i] = mul[i][0 +: 8]+mul[i][8+:8]+mul[i][16+:8]+mul[i][24+:8]+mul[i][32 +:8]+mul[i][40+:8]+mul[i][48+:8]+mul[i][56+:8] +  i_weights_288[i*72+64+:8];
            assign res[i] = sum[i] > 0?1:0;
        end
        //找到第一个跳转指令位置
        wire[3:0] j_tmp[4:0];
        wire[3:0] firstJPos;
        //算法思路：从最后一位向前依次看，如果出现了想要的情况，就写入当前的索引，这样就能保证第0位要不然为最先出现的，要不然就是无效值
        assign j_tmp[4] = 15;
        for(i = 3;i >= 0;i = i-1)begin
            assign j_tmp[i] = res[i] == 1?i:j_tmp[i+1];
        end
        assign firstJPos = j_tmp[0];
    endgenerate

    //标记是否预测值中有判定跳转的
    assign o_predictGotJ = firstJPos < i_consecutiveBNum_4?1:0;

    //错误检查与学习逻辑
    assign o_gotErr = i_correctPC == 0? 0:1;
    //存储从头到第一个预测为跳，共有几个B，如果都预测不跳，就是B指令个数
    assign o_passBNum_3 = o_gotErr?-1:(o_predictGotJ?(firstJPos+1):i_consecutiveBNum_4);
    wire[7:0] errPos;
    assign errPos = i_pendingB_8-i_counter_3;
    assign o_newPendingB_8 = o_gotErr?errPos:errPos+o_passBNum_3;

    //找到B后面第一个非B跳转，如果预测所有B都不跳就从这条指令跳了
    wire[3:0] findJ_tmp[10:0];
    wire[3:0] afterBFirstJ;
    assign findJ_tmp[10] = 0;
    generate
        for(i = 9;i >= 0;i = i-1)begin
            assign findJ_tmp[i] = w_jumpGatherTable_8[i][0+:3] != `B&&w_jumpGatherTable_8[i][0+:3] != `NORMAL?i:findJ_tmp[i+1];
        end
        assign afterBFirstJ = findJ_tmp[0];
    endgenerate

    assign o_nextPc_32 = o_gotErr?
    i_correctPC:
    o_predictGotJ ? 
    w_typeAndAddressTable_35[w_jumpGatherTable_8[firstJPos][3+:5]][3+:32]:
    afterBFirstJ == 0?
    i_currentPc_32+i_validSize_4:
    w_alignedInstructionTable_64[w_jumpGatherTable_8[afterBFirstJ][3+:5]][32+:32];
    
    assign o_cutPosition_8 = o_gotErr?
    -1:
    o_predictGotJ ? 
    w_jumpGatherTable_8[firstJPos][3+:5]:
    afterBFirstJ == 0?
    i_alignedInstructionNumber_4-1:
    w_jumpGatherTable_8[afterBFirstJ][3+:5];
    
endmodule