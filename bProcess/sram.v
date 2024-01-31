module sram (
    input clka,
    input ena,
    input wea,
    input [4:0] addra,
    input [8*9-1:0] dina,
    output [8*9-1:0] douta
);

    reg[8*9-1:0] store[31:0];
    assign douta = store[addra];

    always @(posedge clka) begin
        if(ena && wea) begin
            store[addra] <= dina;
        end
    end
    
endmodule