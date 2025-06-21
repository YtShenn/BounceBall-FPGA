`timescale 1ns / 1ps

module Bluetooth(
    input clk,//100MHz
    input rst,
    input in_msg,//为蓝牙输入的信号（通过手机）
    output reg [7:0]speed//为接受到的蓝牙信息，作为难度即小球移动速度信息传回主模块
    );
    
    parameter bps_num = 10417;//5;//10417;      //9600bps对应一位信号需要的clk时钟周期数
    reg [13:0]clk_cnt = 0;          //时钟个数计数
    reg [4:0]msg_cnt = 0;           //计数message的位数，表征传递进行到了第几位
    reg is_counting;                //记录是否处在信号采集周期内
    
    reg detect1,detect2;            //辅助监测蓝牙起始信号到来的变量
    wire start;                    //判断第一个0位，表示传递开始
    reg is_done;        //一个周期读取完成标志
    
    //检测开始位到来
    always @ (posedge clk or posedge rst)
    begin
        if(rst)
        begin
            detect1 <= 1'b1;
            detect2 <= 1'b1;
        end
        else
        begin
            detect1 <= in_msg;
            detect2 <= detect1;
        end
    end        
    assign start = detect2 & !detect1; //检测开始位的到来 发送一个高脉冲
    
    //生成信号采集脉冲
    wire BPS_CLK;//信号采集脉冲
    always @( posedge clk or posedge rst )
    begin
        if(rst)
            clk_cnt <= 14'd0;
        else if(clk_cnt == bps_num - 1)
            clk_cnt <= 14'd0;
        else if(is_counting)
            clk_cnt <= clk_cnt + 1'b1;
        else 
            clk_cnt <= 14'd0;
    end
    assign BPS_CLK = ( clk_cnt == bps_num/2 ) ? 1'b1 : 1'b0;//在数据位的中间产生采集脉冲
    
    //数据接收    
    always @ (posedge clk or posedge rst)
    begin
        if(rst)
        begin
            msg_cnt <= 4'd0;
            speed <= 8'd0;
            is_counting <= 1'd0;
            is_done <= 1'd0;
        end
        else// if(RX_En_Sig)
        begin
            case (msg_cnt)                            
            4'd0 :                      //检测到下降沿  //通信开始的信号
                if(start) 
                begin 
                    msg_cnt <= msg_cnt+1'b1; 
                    is_counting <= 1'b1; 
                end
            4'd1 :                        //起始位
                if(BPS_CLK) 
                    msg_cnt <= msg_cnt+1'b1;
            4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9 :      //数据位        //数据位的存储 先低位后高位    
                if(BPS_CLK) 
                begin 
                    msg_cnt <= msg_cnt+1'b1; 
                    speed[msg_cnt-2] = in_msg; 
                end
            4'd10 :                  //停止位
               if(BPS_CLK) 
                   msg_cnt <= msg_cnt+1'b1; 
            4'd11 :
            begin 
               msg_cnt <= msg_cnt+1'b1; 
               is_done <= 1'b1; //一个周期完成标志置1
               is_counting <= 1'b0; 
            end
            4'd12 :
            begin 
                msg_cnt <= 1'b0; 
                is_done <= 1'b0; //一个周期完成标志置1
            end  
            endcase
        end
    end
endmodule
