module bcorrect (
    input fire,
    input rst,
    input[41:0] i_data,
    output[2:0] o_counter,
    output[31:0] o_correctpc,
    output[7:0] o_errPos
);
    reg[2:0] counter;
    reg[31:0] correctpc;
    reg[7:0] errPos;
    assign o_correctpc = correctpc;
    assign o_counter = counter;
    assign o_errPos = errPos;

    always @(posedge fire or negedge rst) begin
        if(!rst)begin
            counter <= 0;
            correctpc <= 0;
            errPos <= 0;
        end
        else begin
            counter <= i_data[40] == 1?counter+1:0;
            correctpc <= i_data[39:8];
            errPos <= i_data[7:0];
        end
    end
    
endmodule