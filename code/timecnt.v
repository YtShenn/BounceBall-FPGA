`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/17 18:27:51
// Design Name: 
// Module Name: timecnt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timecnt(
    input clk,  //100MHz
    input rst,  //高电平有效
    input lose, //游戏失败信号，1为失败，上升沿需要计时停止，下降沿需要清零
    output reg [15:0]Time=0
);
    
    //生成1hz=1s时钟信号
    reg clk_1Hz = 0;
    integer clk_cnt = 0;
    always @(posedge clk)
    begin
        if(clk_cnt + 1 == 100000000/2)
        begin
            clk_cnt <= 0;
            clk_1Hz <= ~clk_1Hz;
        end
        else
            clk_cnt <= clk_cnt + 1;
    end  
    //计时
    always @ (posedge clk_1Hz or posedge rst)
    begin
        if(rst==1'b1)
            Time<=0;
        else if(lose==1)
            Time<=Time;
        else
            Time<=Time+1;
    end 
endmodule
