module bcorrect (
    input fire,
    input wire[34:0] data
);
    reg[2:0] counter;
    reg[31:0] correctpc;

    always @(posedge fire) begin
        counter <= data[34:32];
        correctpc <= data[31:0];
    end
    
endmodule