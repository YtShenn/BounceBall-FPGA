`timescale 1ns / 1ps

module Bluetooth(
    input clk,//100MHz
    input rst,
    input in_msg,//Ϊ����������źţ�ͨ���ֻ���
    output reg [7:0]speed//Ϊ���ܵ���������Ϣ����Ϊ�Ѷȼ�С���ƶ��ٶ���Ϣ������ģ��
    );
    
    parameter bps_num = 10417;//5;//10417;      //9600bps��Ӧһλ�ź���Ҫ��clkʱ��������
    reg [13:0]clk_cnt = 0;          //ʱ�Ӹ�������
    reg [4:0]msg_cnt = 0;           //����message��λ�����������ݽ��е��˵ڼ�λ
    reg is_counting;                //��¼�Ƿ����źŲɼ�������
    
    reg detect1,detect2;            //�������������ʼ�źŵ����ı���
    wire start;                    //�жϵ�һ��0λ����ʾ���ݿ�ʼ
    reg is_done;        //һ�����ڶ�ȡ��ɱ�־
    
    //��⿪ʼλ����
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
    assign start = detect2 & !detect1; //��⿪ʼλ�ĵ��� ����һ��������
    
    //�����źŲɼ�����
    wire BPS_CLK;//�źŲɼ�����
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
    assign BPS_CLK = ( clk_cnt == bps_num/2 ) ? 1'b1 : 1'b0;//������λ���м�����ɼ�����
    
    //���ݽ���    
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
            4'd0 :                      //��⵽�½���  //ͨ�ſ�ʼ���ź�
                if(start) 
                begin 
                    msg_cnt <= msg_cnt+1'b1; 
                    is_counting <= 1'b1; 
                end
            4'd1 :                        //��ʼλ
                if(BPS_CLK) 
                    msg_cnt <= msg_cnt+1'b1;
            4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9 :      //����λ        //����λ�Ĵ洢 �ȵ�λ���λ    
                if(BPS_CLK) 
                begin 
                    msg_cnt <= msg_cnt+1'b1; 
                    speed[msg_cnt-2] = in_msg; 
                end
            4'd10 :                  //ֹͣλ
               if(BPS_CLK) 
                   msg_cnt <= msg_cnt+1'b1; 
            4'd11 :
            begin 
               msg_cnt <= msg_cnt+1'b1; 
               is_done <= 1'b1; //һ��������ɱ�־��1
               is_counting <= 1'b0; 
            end
            4'd12 :
            begin 
                msg_cnt <= 1'b0; 
                is_done <= 1'b0; //һ��������ɱ�־��1
            end  
            endcase
        end
    end
endmodule
