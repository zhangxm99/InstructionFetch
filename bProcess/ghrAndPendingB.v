module ghrAndPendingB (
    input fire,
    input rst,
    input[7:0] i_newPendingB_8,
    input i_predictGotJ,
    input[2:0] i_passBNum_3,
    output[7:0] o_pendingB_8,
    output[19:0] o_globalHistoryRegister_20
);

    //在流水线中等待执行的B指令数量
    reg[7:0] r_pendingB_8;
    //全局历史寄存器
    reg[19:0] r_globalHistoryRegister_20;

    assign o_globalHistoryRegister_20 = r_globalHistoryRegister_20;
    assign o_pendingB_8 = r_pendingB_8;

    wire[19:0] rightShift,correctRightShift;
    assign rightShift = r_globalHistoryRegister_20 >> (i_newPendingB_8-1);
    assign correctRightShift = {rightShift[19:1],~rightShift[0]};


    always @(posedge fire or negedge rst) begin
        if(!rst)begin
            r_pendingB_8 <= 0;
            r_globalHistoryRegister_20 <= 0;
        end
        else begin
            r_pendingB_8 <= i_newPendingB_8;

            r_globalHistoryRegister_20 <= (i_passBNum_3 != 3'b111)?
            ((r_globalHistoryRegister_20 << i_passBNum_3) | i_predictGotJ) :
            correctRightShift;
        end
    end


endmodule