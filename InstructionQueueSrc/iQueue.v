`define ISSUEWIDTH 4
`define BUFFERSIZE 10
`define TABLESIZE 10

module iQueue(
    input i_drive,
    input rst,
    input i_freeNext,
    input [7:0] i_cutPosition_8,
    input [2:0] i_type_3,
    input [2:0] i_firstJPos_3,
    input [31:0] i_predictAddr_32,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    input [4*8-1:0] i_first4EntryofJumpGatherTable_32,
    output [7:0] o_room_8,
    output [64*4-1:0] o_PCAndInstr_256,
    output [267:0] o_dataForBack_268,
    output o_driveNext,
    output o_free
);

    reg [32*2*`BUFFERSIZE:0] buffer;
    //剩余可容纳条数、目前有的条数
    reg [7:0] room, num;
    assign o_room_8 = room;
    assign o_PCAndInstr_256 = buffer[64*4-1:0];

    genvar i;
    generate
        for(i = 0;i < 4;i = i + 1)begin
            assign o_dataForBack_268[i * 67 +: 32] = i_type_3 == 0?32'b0 : i_type_3 == 1 ? (i == i_firstJPos_3?i_predictAddr_32:32'b0) : i_predictAddr_32;
            assign o_dataForBack_268[i * 67 + 32 +: 32] = i_alignedInstructionTableBus_640[i_first4EntryofJumpGatherTable_32[i*8+3+:5]*64 +32 +: 32];
            if(i > 0)  begin
                assign o_dataForBack_268[i * 67 + 64 +: 3] = i_type_3 == 1 ? (i <= i_firstJPos_3 ? 1 : 0) : 0;
            end
            else begin
                assign o_dataForBack_268[i * 67 + 64 +: 3] = i_type_3;
            end
        end
    endgenerate

    wire fire;
    cFifo1 cFifo1(.i_drive(i_drive),
                  .rst(rst),
                  .i_freeNext(i_freeNext),
                  .o_free(o_free),
                  .o_driveNext(o_driveNext),
                  .o_fire_1(fire));

    wire[64*`TABLESIZE-1:0] final;
    assign final = (i_alignedInstructionTableBus_640 << (`TABLESIZE-1-i_cutPosition_8)*64) >> (`TABLESIZE-1-i_cutPosition_8)*64;

    wire[32*2*`BUFFERSIZE-1:0] newbuffer;
    //先移位清掉之前的，再加上本轮取得的
    assign newbuffer = (buffer >> (64*`ISSUEWIDTH)) | (final << (num * 64));

    wire [64*4-1:0] nops = {64'h13,64'h13,64'h13,64'h13} << (4-(num + i_cutPosition_8 + 1))*64;

    always @(negedge rst or posedge fire) begin
        if (!rst || i_cutPosition_8 == 8'b11111111 ) begin
            num <= 0;
            room <= `BUFFERSIZE;
            buffer <= 0;
        end
        else begin
            if(num + i_cutPosition_8 + 1 < `ISSUEWIDTH ) begin
                num <= 0;
                room <= `BUFFERSIZE;
                //不够发射宽度就补nop
                buffer <= nops | newbuffer;
            end
            else begin
                room <= room + `ISSUEWIDTH - (i_cutPosition_8 + 1);
                num <= num - `ISSUEWIDTH + (i_cutPosition_8 + 1);
                buffer <= newbuffer;
            end

        end
    end

    
endmodule