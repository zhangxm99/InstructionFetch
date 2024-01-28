`define NORMAL 0
`define B 1
`define J 2
`define JALR 3
`define CALL 4
`define RET 5

module nbjprocess (
    input fire,
    input wire[7:0] i_firstJTableEntry,
    input wire[349:0] i_typeAndAddressTableBus_350,
    output wire[31:0] o_nextPc_32,
    output wire[7:0] o_cutPosition_8
);

    assign type = i_firstJTableEntry[0+:3];
    assign jaddr = i_typeAndAddressTableBus_350[i_firstJTableEntry[3+:5]*35+3 +: 32];
    assign o_cutPosition_8 = i_firstJTableEntry[3+:5];
    assign o_nextPc_32 = type == `RET?RAS[0+:32]:jaddr;

    reg[32*10-1:0] RAS;

    always @(posedge fire) begin
        RAS = type == `CALL?((RAS<<32) | jaddr):(type == `RET?(RAS>>32):RAS);
    end


    
endmodule