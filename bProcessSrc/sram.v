module sram (
    input clka,
    input ena,
    input wea,
    input rst,
    input [4:0] addra,
    input [8*9-1:0] dina,
    output [8*9-1:0] douta
);

    reg[8*9-1:0] store[31:0];
    assign douta = store[addra];
    integer i;
    always @(posedge clka or negedge rst) begin
        if(!rst)begin
            for(i = 0;i < 32;i = i+1)begin
                store[i] <= 0;
            end
        end
        else if(ena && wea) begin
            store[addra] <= dina;
        end
    end
    
endmodule