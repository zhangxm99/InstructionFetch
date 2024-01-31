module weightTable (
    input i_fire,
    input rst,
    input [8*4-1:0] i_weightsAddr_32,
    input [19-1:0] i_globalHistoryRegister_20,
    input [7:0] i_errPos,
    input i_gotErr,
    output [8*9*4-1:0] o_weights_288
);
    //状态变量：如果是0，则当前fire是用来读取权重向量的
    //如果是1，则当前fire是用来根据NEWGHR来进行读取待更新权重向量的
    //如果是2，则当前fire是用来将新的权重向量写入SRAM的
    reg[1:0] State;

    wire[8*4-1:0] read_addr;
    assign correctRes = i_globalHistoryRegister_20[0] == 1?1:-1;
    assign read_en = State == 0 || State == 1? 1:0;
    assign read_addr = State == 0?i_weightsAddr_32:{i_errPos,i_errPos,i_errPos,i_errPos};//这里地址相同会使得Sram中只有一个被选中，可以省电
    assign write_en = State == 2&&i_gotErr?1:0;
    wire[7:0] write_addr;
    assign write_addr = i_errPos;

    wire[8*9-1:0] newWeights;

    genvar i;
    generate
        for(i = 0;i < 8;i = i+1)begin
            assign newWeights[i*8+:8] = o_weights_288[i*8] + ((i_globalHistoryRegister_20[i+1] == correctRes)?1:-1);
        end
        assign newWeights[8*8+:8] = o_weights_288[8*8+:8] + correctRes;
    endgenerate

    fourWayReadSram fourWayReadSram(.i_fire(i_fire),
                    .write_en(write_en),
                    .read_en(read_en),
                    .rst(rst),
                    .i_writeAddr(write_addr),
                    .i_writeData(newWeights),
                    .i_readAddr(read_addr),
                    .o_datas(o_weights_288));


    always @(negedge rst) begin
        State <= 0;
    end
    
endmodule