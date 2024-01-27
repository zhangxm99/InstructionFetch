//四路读一路写SRAM
module fourWayReadSram (
    input i_fire,
    input rst,
    input write_en,
    input read_en,
    input [7:0] i_writeAddr,
    input [8*9-1:0] i_writeData,
    input [8*4-1:0] i_readAddr,
    output [8*9*4-1:0] o_datas
);

    genvar i;
    generate
        wire [2:0] mod[3:0];
        for(i = 0;i < 4;i = i+1)begin
            assign mod[i] = i_readAddr[i*8+:8] % 8;
        end

        wire[7:0] cs;
        wire[7:0] readen;
        wire[2:0] write_offset;
        wire[7:0] writeen;
        wire[4:0] writeSelectAddr;
        assign writeSelectAddr = i_writeAddr>>3;
        assign write_offset = i_writeAddr%8;

        for(i = 0;i < 8;i = i+1)begin
            assign cs[i] = mod[0] == i || mod[1] == i || mod[2] == i || mod[3] == i;
            //默认只能要么读要么写，所以如果写的电平拉高就把所有读电平拉低
            assign readen[i] = read_en?cs[i]:0;
            assign writeen[i] = (write_en && write_offset == i)?1:0;
        end
    endgenerate

    wire[8*9-1:0] data[7:0];
    generate
        wire[4:0] readSelectAddr[7:0];
        wire[4:0] selectAddr[7:0];
        for(i = 0;i < 8;i = i+1)begin
            assign readSelectAddr[i] = mod[0] == i?(i_readAddr[7:0]>>3):(mod[1] == i?(i_readAddr[15:8]>>3):(mod[2] == i?(i_readAddr[23:16]>>3):(mod[3] == i?(i_readAddr[31:24]>>3):0)));
            assign selectAddr[i] = write_en?writeSelectAddr:readSelectAddr[i];
            //228/8 per block
            // SRAM SRAM(.fire(i_fire),
            //           .csen(cs[i]),
            //           .readen(readen[i]),
            //           .writeen(writeen[i]),
            //           .rst(rst),
            //           .i_readAddr(readSelectAddr[i]),
            //           .i_writeAddr(writeSelectAddr),
            //           .i_writeData(i_writeData),
            //           .o_data(data[i]));
            SRAM SRAM(.fire(i_fire),
                      .writeen(writeen[i]),
                      .addr(selectAddr[i]),
                      .o_data(data[i]));
        end
    endgenerate
    assign o_datas = {data[mod[3]],data[mod[2]],data[mod[1]],data[mod[0]]};


    
endmodule