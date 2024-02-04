`define ISSUEWIDTH 4
`define BUFFERSIZE 10
`define TABLESIZE 10

module iQueue(
    input i_drive,
    input rst,
    input i_freeNext,
    input[7:0] i_cutPostion_8,
    input[64*10-1:0] i_alignedInstructionTable,
    output[7:0] o_room,
    output [96*4-1:0] o_PCAndInstr,
    output o_driveNext,
    output o_free
);

    reg [32*2*`BUFFERSIZE:0] buffer;
    //剩余可容纳条数、目前有的条数
    reg [7:0] room, num;
    assign o_room = room;
    assign o_PCAndInstr = buffer[64*4-1:0];

    wire fire;
    cFifo1 cFifo1(.i_drive(i_drive),
                  .rst(rst),
                  .i_freeNext(i_freeNext),
                  .o_free(o_free),
                  .o_driveNext(o_driveNext),
                  .o_fire_1(fire));

    genvar i;
    wire[64*`TABLESIZE-1:0] final;
    assign final = (i_alignedInstructionTable << (9-i_cutPostion_8)*64) >> (9-i_cutPostion_8)*64;

    wire[32*2*`BUFFERSIZE-1:0] newbuffer;
    //先移位清掉之前的，再加上本轮取得的
    assign newbuffer = (buffer >> (64*`ISSUEWIDTH)) | (final << (num * 64));

    wire [64*4-1:0] nops = {64'h13,64'h13,64'h13,64'h13} << (4-(num + i_cutPostion_8 + 1))*64;

    always @(negedge rst or posedge fire) begin
        if (!rst || i_cutPostion_8 == 8'b11111111 ) begin
            num <= 0;
            room <= `BUFFERSIZE;
            buffer <= 0;
        end
        else begin
            if(num + i_cutPostion_8 + 1 < `ISSUEWIDTH ) begin
                num <= 0;
                room <= `BUFFERSIZE;
                //不够发射宽度就补nop
                buffer <= nops | newbuffer;
            end
            else begin
                room <= room + `ISSUEWIDTH - (i_cutPostion_8 + 1);
                num <= num - `ISSUEWIDTH + (i_cutPostion_8 + 1);
                buffer <= newbuffer;
            end

        end
    end

    
endmodule