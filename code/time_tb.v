`timescale 1ns / 1ps

//����ʱҪ��time_cntģ�����ʱȡ�������ܿ�����ȷ����ͼ
module Display7_tb;
    reg clk;  //100MHz
    reg rst;  //�ߵ�ƽ��Ч
    reg lose; //��Ϸʧ���źţ�1Ϊʧ�ܣ���������Ҫ��ʱֹͣ���½�����Ҫ����
   // reg [15:0]Time;
    reg [15:0]grade;  //�÷�
    wire [6:0]oData;  //���
    //wire [15:0]tmp;
    //wire [2:0]cnt;
    wire [7:0]AN; 
    Display7 uut(
        .clk(clk),  //100MHz
        .rst(rst),  //�ߵ�ƽ��Ч
        .lose(lose), //��Ϸʧ���źţ�1Ϊʧ�ܣ���������Ҫ��ʱֹͣ���½�����Ҫ����
       // .Time(Time),
        .grade(grade),  //�÷�
        .oData(oData),  //���
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
    reg rst;  //�ߵ�ƽ��Ч
    reg lose; //��Ϸʧ���źţ�1Ϊʧ�ܣ���������Ҫ��ʱֹͣ���½�����Ҫ����
    wire [15:0]Time;
    timecnt uut(
        .clk(clk),  //100MHz
        .rst(rst),  //�ߵ�ƽ��Ч
        .lose(lose), //��Ϸʧ���źţ�1Ϊʧ�ܣ���������Ҫ��ʱֹͣ���½�����Ҫ����
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
