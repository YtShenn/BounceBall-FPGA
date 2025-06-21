`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/09 15:02:53
// Design Name: 
// Module Name: Top
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


module Top(
    input clk, //输入时钟，100MHz
    input rst , // 系统复位
    
    //VGA
    input right, //挡板右移，高电平有效
    input left, //挡板左移，高电平有效
    output hs, //VGA行同步信号
    output vs, //VGA场同步信号
    output [3:0] Red,
    output [3:0] Green,
    output [3:0] Blue,
    
    //Display7
    output [6:0]oData,  //输出
    output [7:0]AN,  //片选
    
    //BlueTooth
    input in_msg,//为蓝牙输入的信号（通过手机）
    
    //mp3
    input DREQ,//mp3向开发板请求数据信号
    output RSET,//mp3硬件重置信号
    output CS,//mp3寄存器片选信号，低电平有效
    output DCS,//mp3数据片选信号，低电平有效
    output SI,//向mp3输出的数据
    output SCLK//mp3的spi总线时钟线
    );
    wire [7:0] speed;//速度
    Bluetooth bt(
        .clk(clk),//100MHz
        .rst(rst),
        .in_msg(in_msg),//为蓝牙输入的信号（通过手机）
        .speed(speed)//为接受到的蓝牙信息，作为难度即小球移动速度信息传回主模块
        );
    
    wire lose; //游戏失败信号，没能成功挡住球的话就会触发一个高电平脉冲，用于数码管计数   
    wire [15:0] grade;//得分    
    VGA vga(
        .clk(clk), //输入时钟，100MHz
        .rst(rst) , // 系统复位
        .right(right), //挡板右移，高电平有效
        .left(left), //挡板左移，高电平有效
        .speed(speed), //板移动速度.
        .hs(hs), //VGA行同步信号
        .vs(vs), //VGA场同步信号
        .Red(Red),
        .Green(Green),
        .Blue(Blue),
        .lose(lose), //游戏失败信号，没能成功挡住球的话就会触发一个高电平脉冲，用于数码管计数   
        .grade(grade)//得分
        );
    Display7 ds(
       .clk(clk),  //100MHz
       .rst(rst),  //高电平有效
       .grade(grade),  //得分
       //.Time(Time),
       .lose(lose),
       .oData(oData),  //输出
       .AN(AN)  //片选
       );
    
    MP3_2 mp3(
        .clk(clk),//100MHz
        .rst(rst),//置位信号，高电平有效
        .choice(speed),//歌曲选择
        .DREQ(DREQ),//mp3向开发板请求数据信号
        .RSET(RSET),//mp3硬件重置信号
        .CS(CS),//mp3寄存器片选信号，低电平有效
        .DCS(DCS),//mp3数据片选信号，低电平有效
        .SI(SI),//向mp3输出的数据
        .SCLK(SCLK),//mp3的spi总线时钟线
        .lose(lose)//游戏失败，音乐播放暂停,1是停止
        );
    
endmodule
