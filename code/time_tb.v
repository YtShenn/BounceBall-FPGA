`timescale 1ns / 1ps

//测试时要将time_cnt模块里分时取消掉才能看到正确波形图
module Display7_tb;
    reg clk;  //100MHz
    reg rst;  //高电平有效
    reg lose; //游戏失败信号，1为失败，上升沿需要计时停止，下降沿需要清零
   // reg [15:0]Time;
    reg [15:0]grade;  //得分
    wire [6:0]oData;  //输出
    //wire [15:0]tmp;
    //wire [2:0]cnt;
    wire [7:0]AN; 
    Display7 uut(
        .clk(clk),  //100MHz
        .rst(rst),  //高电平有效
        .lose(lose), //游戏失败信号，1为失败，上升沿需要计时停止，下降沿需要清零
       // .Time(Time),
        .grade(grade),  //得分
        .oData(oData),  //输出
        //.cnt(cnt),
        //.tmp(tmp),
        .AN(AN)
    );
    
    initial clk=0;
    always #5 clk=~clk;
    
    initial
    begin
    lose=0;
    rst=0;
    grade=20;
    #80;
    lose=1;
    #80;
    lose=0;
    grade=55;
    #80;
    rst=1;
    #20;
    end
    
endmodule
/*module time_tb;
    reg clk;  //100MHz
    reg rst;  //高电平有效
    reg lose; //游戏失败信号，1为失败，上升沿需要计时停止，下降沿需要清零
    wire [15:0]Time;
    timecnt uut(
        .clk(clk),  //100MHz
        .rst(rst),  //高电平有效
        .lose(lose), //游戏失败信号，1为失败，上升沿需要计时停止，下降沿需要清零
        .Time(Time)
    );
    
    initial clk=0;
    always #5 clk=~clk;
    
    initial
    begin
    lose=0;
    rst=0;
    #20;
    lose=1;
    #10;
    lose=0;
    #20;
    rst=1;
    #20;
    end
    
endmodule*/
