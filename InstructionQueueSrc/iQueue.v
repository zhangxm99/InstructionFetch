`define ISSUEWIDTH 4
`define BUFFERSIZE 10

module iQueue(
    input i_drive,
    input rst,
    input i_freeNext,
    input[7*0] i_cutPostion_8,
    input[64*10-1:0] i_alignedInstructionTable,
    output [96*4-1:0] o_predictAndPCAndInstr,
    output o_driveNext,
    output o_free
);

    reg [34*3*`BUFFERSIZE:0] buffer;
    //剩余条数
    reg [4:0] room, index;

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
        for(i = 0;i < 10 ;i = i+1)begin
            assign tmp[i*96 +: 64] = i_alignedInstructionTable[i*64+:64];
        end
        assign final = (tmp << (9-i_cutPostion_8)*96) >> (9-i_cutPostion_8)*96;
    endgenerate

    wire[34*3*`BUFFERSIZE:0] newbuffer;
    assign newbuffer = 

    


    always @(negedge rst or posedge fire) begin
        if (!rst) begin
            room <= 0;
        end
        else begin
            buffer = buffer >> 4*96
            room <= room 
        end
    end

    
endmodule