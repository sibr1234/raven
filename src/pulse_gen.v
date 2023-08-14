module pulse_gen #(parameter divider = 250, parameter width= 8)
(
    input wire clk,
    input wire reset_n,
    output reg pulse
    );

   reg [width-1 :0 ] cnt; 

    always @ (posedge clk | ~reset_n ) begin 
        if(~reset_n) begin
          cnt <= 0;
          pulse = 1'b0;
        end
          else begin
            if(cnt == (divider-1)) begin
              cnt <= 0;
              pulse = 1'b1;
            end
            else begin
              cnt <= cnt + 1;
              pulse = 1'b0;
            end
          end
      end      
endmodule
