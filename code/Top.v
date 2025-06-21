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
    input clk, //����ʱ�ӣ�100MHz
    input rst , // ϵͳ��λ
    
    //VGA
    input right, //�������ƣ��ߵ�ƽ��Ч
    input left, //�������ƣ��ߵ�ƽ��Ч
    output hs, //VGA��ͬ���ź�
    output vs, //VGA��ͬ���ź�
    output [3:0] Red,
    output [3:0] Green,
    output [3:0] Blue,
    
    //Display7
    output [6:0]oData,  //���
    output [7:0]AN,  //Ƭѡ
    
    //BlueTooth
    input in_msg,//Ϊ����������źţ�ͨ���ֻ���
    
    //mp3
    input DREQ,//mp3�򿪷������������ź�
    output RSET,//mp3Ӳ�������ź�
    output CS,//mp3�Ĵ���Ƭѡ�źţ��͵�ƽ��Ч
    output DCS,//mp3����Ƭѡ�źţ��͵�ƽ��Ч
    output SI,//��mp3���������
    output SCLK//mp3��spi����ʱ����
    );
    wire [7:0] speed;//�ٶ�
    Bluetooth bt(
        .clk(clk),//100MHz
        .rst(rst),
        .in_msg(in_msg),//Ϊ����������źţ�ͨ���ֻ���
        .speed(speed)//Ϊ���ܵ���������Ϣ����Ϊ�Ѷȼ�С���ƶ��ٶ���Ϣ������ģ��
        );
    
    wire lose; //��Ϸʧ���źţ�û�ܳɹ���ס��Ļ��ͻᴥ��һ���ߵ�ƽ���壬��������ܼ���   
    wire [15:0] grade;//�÷�    
    VGA vga(
        .clk(clk), //����ʱ�ӣ�100MHz
        .rst(rst) , // ϵͳ��λ
        .right(right), //�������ƣ��ߵ�ƽ��Ч
        .left(left), //�������ƣ��ߵ�ƽ��Ч
        .speed(speed), //���ƶ��ٶ�.
        .hs(hs), //VGA��ͬ���ź�
        .vs(vs), //VGA��ͬ���ź�
        .Red(Red),
        .Green(Green),
        .Blue(Blue),
        .lose(lose), //��Ϸʧ���źţ�û�ܳɹ���ס��Ļ��ͻᴥ��һ���ߵ�ƽ���壬��������ܼ���   
        .grade(grade)//�÷�
        );
    Display7 ds(
       .clk(clk),  //100MHz
       .rst(rst),  //�ߵ�ƽ��Ч
       .grade(grade),  //�÷�
       //.Time(Time),
       .lose(lose),
       .oData(oData),  //���
       .AN(AN)  //Ƭѡ
       );
    
    MP3_2 mp3(
        .clk(clk),//100MHz
        .rst(rst),//��λ�źţ��ߵ�ƽ��Ч
        .choice(speed),//����ѡ��
        .DREQ(DREQ),//mp3�򿪷������������ź�
        .RSET(RSET),//mp3Ӳ�������ź�
        .CS(CS),//mp3�Ĵ���Ƭѡ�źţ��͵�ƽ��Ч
        .DCS(DCS),//mp3����Ƭѡ�źţ��͵�ƽ��Ч
        .SI(SI),//��mp3���������
        .SCLK(SCLK),//mp3��spi����ʱ����
        .lose(lose)//��Ϸʧ�ܣ����ֲ�����ͣ,1��ֹͣ
        );
    
endmodule
