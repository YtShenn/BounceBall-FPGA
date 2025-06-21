`timescale 1ns / 1ps
module MP3_2(
    input clk,//100MHz
    input rst,//置位信号，高电平有效
    input [7:0]choice,//歌曲选择
   input DREQ,//mp3向开发板请求数据信号
   output reg RSET=0,//mp3硬件重置信号
   output reg CS=1,//mp3寄存器片选信号，低电平有效
   output reg DCS=1,//mp3数据片选信号，低电平有效
   output reg SI,//向mp3输出的数据
   output reg SCLK=0,//mp3的spi总线时钟线
   //待改为input:   
   input lose//游戏失败，音乐播放暂停,1是停止
    );
    reg [20:0] addr;//在ROM中的地址
    reg [31:0] data;//音乐数据
    wire [31:0] data0;//音乐1
    wire [31:0] data1;//音乐2
    wire [31:0] data2;//音乐3    
    
    reg [7:0]pre_id = 0;//当前是第几首音乐
    
    parameter size0 = 1684;//15178;
    parameter size1 = 691;
    parameter size2 = 2412;
    reg [15:0]MUSIC_SIZE = size0;
    //parameter MUSIC_SIZE = 691;
    
    //状态编码
    parameter  INIT=0,//初始
                CMD_PRESET=1,      //cmd信号传送前设置
                CMD_SEND=2,         //cmd信号传送
                DATA_PRESET=3,
                DATA_SEND=4;
                
    reg [2:0]cmd_select;             //指令选择
    reg [31:0]cmd;              //指令内容
   parameter  S_RST=0,        //软复位
               SET_VOL=1,      //音量
               SET_BASS=2,     //重音
               SET_CLKF=3;      //时钟
    
    reg [2:0]   state=INIT;        //当前状态
    
    reg [5:0] cnt_32bit;        //记录传送数据给mp3时是否传满32bit
    
    //生成1Mhz时钟信号
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
            INIT://初始化、硬复位
            begin
                addr<=0;
                cmd_select<=S_RST;
                cnt_32bit<=0;
                CS<=1;
                DCS<=1;
                RSET<=0;
                SCLK<=0;
                if(rst==0)  //不复位，后续lose讯号控制音乐播放可以放这
                    state<=CMD_PRESET;
                else        //复位
                    state<=INIT;
            end
    
            CMD_PRESET://设置cmd信号，配置寄存器
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
                    state<=CMD_SEND;    //转到发送cmd
                end
                else
                begin
                    cmd_select<=0;
                    state<=DATA_PRESET; //寄存器配置完毕，转到传输数据
                end
            end
            
            CMD_SEND://发送cmd给mp3，配置寄存器
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
                if(addr>=MUSIC_SIZE||lose==1)    //播放完毕，循环播放
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
    
            DATA_SEND://数据传送
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
    
    //配置IP核
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