`define ISSUEWIDTH 4
`define BUFFERSIZE 10

module iQueue(
    input i_drive,
    input rst,
    input i_freeNext,
    input[7*0] i_cutPostion_8,
    input[64*10-1:0] i_alignedInstructionTable,
    input b_num,
    input[31:0] jumpAddr,
    output [96*4-1:0] o_predictAndPCAndInstr,
    output o_driveNext,
    output o_free
);

    reg [34*3*`BUFFERSIZE:0] buffer;
    //剩余可容纳条数、目前有的条数
    reg [4:0] room, num;

    assign o_predictAndPCAndInstr = buffer[96*4-1:0];

    wire fire;
    cFifo1 cFifo1(.i_drive(i_drive),
                  .rst(rst),
                  .i_freeNext(i_freeNext),
                  .o_free(o_free),
                  .o_driveNext(o_driveNext),
                  .o_fire_1(fire));

    genvar i;
    wire[96*`BUFFERSIZE-1:0] tmp, final;
    generate    
        for(i = 0;i < `BUFFERSIZE;i = i+1)begin
            assign tmp[i*96 +: 64] = i_alignedInstructionTable[i*64+:64];
        end
        assign final = (tmp << (9-i_cutPostion_8)*96) >> (9-i_cutPostion_8)*96;
    endgenerate

    wire[34*3*`BUFFERSIZE:0] newbuffer;
    //先移位清掉之前的，再加上本轮取得的
    assign newbuffer = (buffer >> (96*`ISSUEWIDTH)) | (final << (num * 96));

    always @(negedge rst or posedge fire) begin
        if (!rst || i_cutPostion_8 == -1 ) begin
            num <= 0;
            room <= `BUFFERSIZE;
            buffer <= 0;
        end
        else begin
            buffer <= newbuffer;
            if(num + i_cutPostion_8 + 1 < `ISSUEWIDTH ) begin
                num <= 0;
                room <= `BUFFERSIZE;
                //不够发射宽度就补nop
                buffer <= ({96'h13,96'h13,96'h13,96'h13} << (4-(num + i_cutPostion_8 + 1))) | newbuffer;
            end
            else begin
                room <= room + `ISSUEWIDTH - (i_cutPostion_8 + 1);
                num <= num - `ISSUEWIDTH + (i_cutPostion_8 + 1);
                buffer <= newbuffer;
            end

        end
    end

    
endmodule