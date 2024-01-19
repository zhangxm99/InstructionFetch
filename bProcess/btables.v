module btables (
    input fire,
    input rst,
    input wire[7:0] i_newPendingB_8,
    input wire[2:0] i_passBNum_3,
    input wire[7:0] i_errWeightPos_8,
    input wire[8*9-1:0] i_newWeights_72,
    input wire[33*4-1:0] i_newGHREntry_132,
    output wire[7:0] o_pendingB_8,
    output wire[33*20-1:0] o_globalHistoryRegister_660,
    output wire[8*9*228-1:0] o_weightTable_16416
);
    //在流水线中等待执行的B指令数量
    reg[7:0] r_pendingB_8;
    //全局历史寄存器
    reg[33*20-1:0] r_globalHistoryRegister_660;
    //权重表
    reg[9*8-1:0] weightTable_9[227:0];

    assign o_globalHistoryRegister_660 = r_globalHistoryRegister_660;
    assign o_pendingB_8 = r_pendingB_8;
    genvar i;
    generate
    //权重表扁平化输出
    for(i = 0;i < 228;i = i+1)
        assign o_weightTable_16416[i*72+:72] = weightTable_9[i];
    endgenerate

    wire[33*20-1:0] rightShift;
    assign rightShift = (r_globalHistoryRegister_660 >> ((i_newPendingB_8-1)*33));
    assign correctRightShift = {rightShift[33*20-1:1],~rightShift[0]};

    always @(posedge fire or negedge rst) begin
        if(!rst)begin
            r_pendingB_8 <= 0;
            r_globalHistoryRegister_660 <= 0;
            for (integer i = 0; i < 228; i = i + 1) begin
                weightTable_9[i] <= 0;
            end
        end
        r_pendingB_8 <= i_newPendingB_8;

        r_globalHistoryRegister_660 <= i_passBNum_3 != -1?
        ((r_globalHistoryRegister_660 << (i_passBNum_3*33)) | i_newGHREntry_132) :
        correctRightShift;

        weightTable_9[i_errWeightPos_8] <= i_passBNum_3 == -1?
        weightTable_9[i_errWeightPos_8]:
        i_newWeights_72;

    end
    
endmodule