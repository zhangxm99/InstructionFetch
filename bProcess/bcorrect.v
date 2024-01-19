module bcorrect (
    input fire,
    input rst,
    input wire[32:0] i_data,
    output wire[2:0] o_counter,
    output wire[31:0] o_correctpc
);
    reg[2:0] counter;
    reg[31:0] correctpc;
    assign o_correctpc = correctpc;
    assign o_counter = counter;

    always @(posedge fire or negedge rst) begin
        if(!rst)begin
            counter <= 0;
            correctpc <= 0;
        end
        counter <= i_data[32] == 1?counter+1:0;
        correctpc <= i_data[31:0];
    end
    
endmodule