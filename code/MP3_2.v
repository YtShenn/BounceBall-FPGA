`timescale 1ns / 1ps
module MP3_2(
    input clk,//100MHz
    input rst,//��λ�źţ��ߵ�ƽ��Ч
    input [7:0]choice,//����ѡ��
   input DREQ,//mp3�򿪷������������ź�
   output reg RSET=0,//mp3Ӳ�������ź�
   output reg CS=1,//mp3�Ĵ���Ƭѡ�źţ��͵�ƽ��Ч
   output reg DCS=1,//mp3����Ƭѡ�źţ��͵�ƽ��Ч
   output reg SI,//��mp3���������
   output reg SCLK=0,//mp3��spi����ʱ����
   //����Ϊinput:   
   input lose//��Ϸʧ�ܣ����ֲ�����ͣ,1��ֹͣ
    );
    reg [20:0] addr;//��ROM�еĵ�ַ
    reg [31:0] data;//��������
    wire [31:0] data0;//����1
    wire [31:0] data1;//����2
    wire [31:0] data2;//����3    
    
    reg [7:0]pre_id = 0;//��ǰ�ǵڼ�������
    
    parameter size0 = 1684;//15178;
    parameter size1 = 691;
    parameter size2 = 2412;
    reg [15:0]MUSIC_SIZE = size0;
    //parameter MUSIC_SIZE = 691;
    
    //״̬����
    parameter  INIT=0,//��ʼ
                CMD_PRESET=1,      //cmd�źŴ���ǰ����
                CMD_SEND=2,         //cmd�źŴ���
                DATA_PRESET=3,
                DATA_SEND=4;
                
    reg [2:0]cmd_select;             //ָ��ѡ��
    reg [31:0]cmd;              //ָ������
   parameter  S_RST=0,        //��λ
               SET_VOL=1,      //����
               SET_BASS=2,     //����
               SET_CLKF=3;      //ʱ��
    
    reg [2:0]   state=INIT;        //��ǰ״̬
    
    reg [5:0] cnt_32bit;        //��¼�������ݸ�mp3ʱ�Ƿ���32bit
    
    //����1Mhzʱ���ź�
    reg clk_1MHz = 0;
    integer clk_cnt = 0;
    always @(posedge clk)
    begin
        if(clk_cnt + 1 == 100/2)
        begin
            clk_cnt <= 0;
            clk_1MHz <= ~clk_1MHz;
        end
        else
            clk_cnt <= clk_cnt + 1;
    end
    
    always@(posedge clk_1MHz or posedge rst )
    begin
        if(rst==1||pre_id!=choice)
        begin
            state<=INIT;  
            pre_id=choice;          
        end
        else
        begin
            case(state)
            INIT://��ʼ����Ӳ��λ
            begin
                addr<=0;
                cmd_select<=S_RST;
                cnt_32bit<=0;
                CS<=1;
                DCS<=1;
                RSET<=0;
                SCLK<=0;
                if(rst==0)  //����λ������loseѶ�ſ������ֲ��ſ��Է���
                    state<=CMD_PRESET;
                else        //��λ
                    state<=INIT;
            end
    
            CMD_PRESET://����cmd�źţ����üĴ���
            begin
                RSET<=1;
                if(cmd_select < 4 && DREQ)
                begin
                    case(cmd_select)
                        S_RST:      cmd<=32'h02_00_08_04;
                        SET_VOL:    cmd<=32'h02_0B_10_10;
                        SET_BASS:   cmd<=32'h02_02_00_55;
                        SET_CLKF:   cmd<=32'h02_03_98_00;
                    endcase
                    cmd_select<=cmd_select+1;
                    CS<=0;
                    SI<=cmd[32-1-cnt_32bit];
                    cnt_32bit<=1;
                    state<=CMD_SEND;    //ת������cmd
                end
                else
                begin
                    cmd_select<=0;
                    state<=DATA_PRESET; //�Ĵ���������ϣ�ת����������
                end
            end
            
            CMD_SEND://����cmd��mp3�����üĴ���
            begin
                if(DREQ)
                begin
                    if(SCLK)
                    begin
                        if(cnt_32bit<32)
                        begin
                            SI<=cmd[32-1-cnt_32bit];
                            cnt_32bit<=cnt_32bit+1;
                        end
                        else
                        begin
                            CS<=1;
                            cnt_32bit<=0;
                            state<=CMD_PRESET;
                        end
                    end
                    SCLK<=~SCLK;
                end
            end
    
            DATA_PRESET:
            begin
                if(addr>=MUSIC_SIZE||lose==1)    //������ϣ�ѭ������
                begin
                    state<=INIT;
                    //lose<=1;
                    // DCS<=1;
                end
                else if(DREQ)
                begin
                    //lose<=0;
                    DCS<=0;
                    SCLK<=0;
                    //data[31:0]<=data0[31:0];
                    if(pre_id>0)
                    case(pre_id%3)
                        4'd2:
                        begin
                            SI<=data0[31];
                            data<=data0;
                            MUSIC_SIZE<=size0;
                        end
                        4'd1:
                        begin
                            SI<=data1[31];
                            data<=data1;
                            MUSIC_SIZE<=size1;
                        end
                        4'd0:
                        begin
                            SI<=data2[31];
                            data<=data2;
                            MUSIC_SIZE<=size2;
                        end
                    endcase;
                    cnt_32bit<=1;
                    state<=DATA_SEND;
                end
            end
    
            DATA_SEND://���ݴ���
            begin
                if(DREQ)
                begin
                    if(SCLK)
                    begin
                        if(cnt_32bit<32)
                        begin
                            //cnt_32bit<=cnt_32bit+1;
                            SI <= data[32-1-cnt_32bit];
                            cnt_32bit<=cnt_32bit+1;
                        end
                        else
                        begin
                            DCS<=1;
                            cnt_32bit<=0;//
                            addr<=addr+1;
                            state<=DATA_PRESET;
                        end
                    end
                    SCLK<=~SCLK;
                end
            end
    
            default:
                state<=INIT;
            endcase
        end
    end
    
    //����IP��
    music_0 music_0(
      .clka(clk),    // input wire clka
      .addra(addr[10:0]),  // input wire [13 : 0] addra
      .douta(data0[31:0])  // output wire [31 : 0] douta
    );
    music_1 music_1(
        .clka(clk),    // input wire clka
        .addra(addr[11:0]),  // input wire [13 : 0] addra
        .douta(data1[31:0])  // output wire [31 : 0] douta
    );
    music_2 music_2(
        .clka(clk),    // input wire clka
        .addra(addr[11:0]),  // input wire [13 : 0] addra
        .douta(data2[31:0])  // output wire [31 : 0] douta
    );
    
endmodule