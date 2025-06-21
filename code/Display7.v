`timescale 1ns / 1ps


module Display7(
    input clk,  //100MHz
    input rst,  //�ߵ�ƽ��Ч
    input [15:0]grade,  //�÷�
    input lose,
    output reg [6:0]oData,  //���
    output reg [7:0]AN  //Ƭѡ
    );
    //����ʱ�Ӽ�ʱ
    wire [15:0]Time;
    timecnt timeuut(.clk(clk),.rst(rst),.lose(lose),.Time(Time));
    
    //����1000hzʱ���ź�
     reg clk_1000Hz = 0;
     integer clk_cnt = 0;
     always @(posedge clk)
     begin
         if(clk_cnt + 1 == 100000/2)
         begin
             clk_cnt <= 0;
             clk_1000Hz <= ~clk_1000Hz;
         end
         else
             clk_cnt <= clk_cnt + 1;
     end  
     //תʮ������
     reg [15:0]tmp;
     reg [3:0]data[0:7];//8�����֣�ÿ������0-9��Ϊ2��4�η�
     always @(*)
     begin
        tmp = grade;
        data[0] = tmp%10;
        data[1] = (tmp/10)%10;
        data[2] = (tmp/100)%10;
        data[3] = (tmp/1000)%10;
        
        tmp = Time;
        data[4] = tmp%10;
        data[5] = (tmp/10)%10;
        data[6] = (tmp/100)%10;
        data[7] = (tmp/1000)%10;
     end
     
     //Ƭѡ��Ϊ��
     reg [2:0]cnt=0;
     always @ (posedge clk_1000Hz or posedge rst)
     begin
        if(rst)
        begin
            AN <= 8'b11111111;
            cnt <= 0;
        end
        else
        begin
            if(cnt == 7)
                cnt <= 0;
            else 
                cnt <= cnt+1;
            AN <= 8'b11111111;
            if(cnt>=0 && cnt<=7)
                AN[cnt] <= 0;
        end
        //�߶��������ʾ
        case(data[cnt])
                4'd0:  oData <= 7'b1000000;
                4'd1:  oData <= 7'b1111001;
                4'd2:  oData <= 7'b0100100;
                4'd3:  oData <= 7'b0110000;
                4'd4:  oData <= 7'b0011001;                              
                4'd5:  oData <= 7'b0010010;
                4'd6:  oData <= 7'b0000010;
                4'd7:  oData <= 7'b1111000;
                4'd8:  oData <= 7'b0000000;
                4'd9:  oData <= 7'b0010000;
                default: oData <= 7'b1111111;
                endcase
     end
    
endmodule
