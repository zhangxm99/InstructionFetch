module ghrAndPendingB (
    input fire,
    input rst,
    input wire[7:0] i_newPendingB_8,
    input wire[2:0] i_passBNum_3,
    input wire[9*4-1:0] i_newGHREntry_36,
    output wire[7:0] o_pendingB_8,
    output wire[9*20-1:0] o_globalHistoryRegister_180
);

    //在流水线中等待执行的B指令数量
    reg[7:0] r_pendingB_8;
    //全局历史寄存器
    reg[9*20-1:0] r_globalHistoryRegister_180;

    assign o_globalHistoryRegister_180 = r_globalHistoryRegister_180;
    assign o_pendingB_8 = r_pendingB_8;

    wire[9*20-1:0] rightShift;
    assign rightShift = (r_globalHistoryRegister_180 >> ((i_newPendingB_8-1)*9));
    assign correctRightShift = {rightShift[9*20-1:1],~rightShift[0]};


    always @(posedge fire or negedge rst) begin
        if(!rst)begin
            r_pendingB_8 <= 0;
            r_globalHistoryRegister_180 <= 0;
        end
        r_pendingB_8 <= i_newPendingB_8;

        r_globalHistoryRegister_180 <= i_passBNum_3 != -1?
        ((r_globalHistoryRegister_180 << (i_passBNum_3*9)) | i_newGHREntry_36) :
        correctRightShift;
    end


endmodule