`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/02 22:00:46
// Design Name: 
// Module Name: Bluetooth_tb
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

//测试时把Bluetooth模块里bps_num设为5
module Bluetooth_tb;
    reg clk;//100MHz
    reg rst;
    reg in_msg;//为蓝牙输入的信号（通过手机）
    wire [7:0]speed;//为接受到的蓝牙信息，作为难度即小球移动速度信息传回主模块
    Bluetooth uut(.clk(clk),.rst(rst),.in_msg(in_msg),.speed(speed));
    
    initial clk=0;
    always #1 clk=~clk;
    
    initial 
    begin
    rst=0;
    in_msg=1;
    #5;
    in_msg=0;
    #10;
    in_msg=1;
    #10;
    in_msg=0;
    #20;
    in_msg=1;
    #10;
    in_msg=0;
    #10;
    in_msg=1;
    #10;
    in_msg=0;
    #10;
    in_msg=1;
    #20;//含了停止位
    in_msg=1;
    #40;
    
    rst=1;
    #5;
    end
endmodule
