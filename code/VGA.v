`timescale 1ns / 1ps

module VGA(
    input clk, //����ʱ�ӣ�100MHz
    input rst , // ϵͳ��λ
    input right, //�������ƣ��ߵ�ƽ��Ч
    input left, //�������ƣ��ߵ�ƽ��Ч
    input [7:0] speed, //���ƶ��ٶ�
    output hs, //VGA��ͬ���ź�
    output vs, //VGA��ͬ���ź�
    output reg [3:0] Red,
    output reg [3:0] Green,
    output reg [3:0] Blue,
    output lose, //��Ϸʧ���źţ�û�ܳɹ���ס��Ļ��ͻᴥ��һ���ߵ�ƽ���壬��������ܼ���   
    output reg [15:0] grade = 0//�÷�
    );
    //initial fail<=0;
    reg fail=0;
    assign lose=fail;
    // �ֱ���Ϊ640*480ʱ��ʱ�������������
    parameter C_H_SYNC_PULSE=96, 
               C_H_BACK_PORCH=48,
               C_H_ACTIVE_TIME=640,
               C_H_FRONT_PORCH=16,
               C_H_LINE_PERIOD= 800;
    // �ֱ���Ϊ640*480ʱ��ʱ�������������               
    parameter C_V_SYNC_PULSE=2, 
                C_V_BACK_PORCH=33,
                C_V_ACTIVE_TIME=480,
                C_V_FRONT_PORCH=10,
                C_V_FRAME_PERIOD=525;
                    
    parameter Ball_r = 25; //���޸�
    parameter Bar_Width = 165; 
    parameter Bar_Height = 25;
    
    reg [11:0] R_h_cnt; // ��ʱ�������
    reg [11:0] R_v_cnt; // ��ʱ�������
    reg R_clk_25M; // 25MHz������ʱ��
    
    reg [9:0] Ball_X = C_H_SYNC_PULSE + C_H_BACK_PORCH + 0;
    reg [9:0] Ball_Y = C_V_SYNC_PULSE + C_V_BACK_PORCH + 0;
    //reg [3:0]Ball_speed =speed;//���ٶȣ����Ǻ���ͨ���Ѷȸı��Ӧ�ı��ٶȴ�С
    reg Ball_up = 1 ;//��������
    reg Ball_right = 1 ;//��������
    
    reg [9:0] Bar_X = 0;//������
    reg [9:0] Bar_Y = C_V_ACTIVE_TIME - Bar_Height;//������
   
    wire [17:0] Bg_addr1 ; //������ַ1
    wire [17:0] Bg_addr2; //������ַ2
    wire [11:0] Bg_data1; // ���� 1
    wire [11:0] Bg_data2; // ���� 2
    assign Bg_addr1 = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH)*320;
    assign Bg_addr2 = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH - 320) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH)*320;
    reg Bg_PIX_NUM = 640 * 480 ;
    
    wire [16:0] G_addr; //��Ϸʧ�ܱ�����ַ
    wire [11:0] G_data; // ���� 
    assign G_addr = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH - 210) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH - 160)*220;
    
    wire active_flag = (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH))  &&
                            (R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME))  && 
                            (R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH))  &&
                            (R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME)) ; // �����־��������ź�Ϊ1ʱRGB�����ݿ�����ʾ����Ļ��
     //rom
    bg1_rom bg1(clk,Bg_addr1,Bg_data1);
    bg2_rom bg2(clk,Bg_addr2,Bg_data2);
    go_rom go(clk,G_addr,G_data);
    
    reg count = 1'b0;
    //����25MHz������ʱ��
    always @(posedge clk or posedge rst)
    begin
        if(rst)//�ߵ�ƽ��Ч
            R_clk_25M <= 1'b0;
        else
            if(count==1'b1)
            begin
                count=1'b0;
                R_clk_25M <= ~R_clk_25M; 
            end
            else
                count=1'b1;    
    end
    // ������ʱ��
    always @(posedge R_clk_25M or posedge rst)
    begin
        if(rst)
            R_h_cnt <= 12'd0;
        else if(R_h_cnt == C_H_LINE_PERIOD - 1'b1)
            R_h_cnt <= 12'd0;
        else
            R_h_cnt <= R_h_cnt + 1'b1  ;                
    end 
    assign hs = (R_h_cnt < C_H_SYNC_PULSE) ? 1'b0 : 1'b1; 
    // ������ʱ��
    always @(posedge R_clk_25M or posedge rst)
    begin
        if(rst)
            R_v_cnt <=  12'd0;
        else if(R_v_cnt == C_V_FRAME_PERIOD - 1'b1)
            R_v_cnt <=  12'd0;
        else if(R_h_cnt == C_H_LINE_PERIOD - 1'b1)
            R_v_cnt <=  R_v_cnt + 1'b1;
        else
            R_v_cnt <=  R_v_cnt;                        
    end 
    assign vs = (R_v_cnt < C_V_SYNC_PULSE) ? 1'b0 : 1'b1;   
   
    // ���ܣ���ROM�����ͼƬ�������
    always @(posedge R_clk_25M or posedge rst)
    begin
        if(rst)
        begin 
            Red <= 4'b0000;  
            Green <= 4'b0000;  
            Blue <= 4'b0000;
        end
        else if(active_flag)    
        begin
            if(fail==0)
            begin 
                if ((R_h_cnt - Ball_X)*(R_h_cnt - Ball_X) + (R_v_cnt - Ball_Y)*(R_v_cnt - Ball_Y) <= (Ball_r * Ball_r))  
                begin  //��ʾС��
                    Red   <=  4'b1111; // ��ɫС��
                    Green <=  4'b1111; 
                    Blue  <=  4'b0000;  
                end  
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X)  && 
                                 R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X + Bar_Width  - 1'b1)  &&
                                 R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH + Bar_Y                        )  && 
                                 R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + Bar_Y + Bar_Height - 1'b1)  )//��ʾ����,����
                begin//��ɫľ��
                    Red <=  4'b1011;  
                    Green <=  4'b1000;  
                    Blue <=  4'b0101;
                end                
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH )  && 
                   R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 320  - 1'b1)  &&
                   R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                        )  && 
                   R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + 480 - 1'b1)  )
                begin
                    Red       <= Bg_data1[11:8]    ; // ��ɫ����
                    Green     <= Bg_data1[7:4]     ; // ��ɫ����
                    Blue      <= Bg_data1[3:0]      ; // ��ɫ����
                end
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 320 )  && 
                        R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 640  - 1'b1)  &&
                        R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                        )  && 
                        R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + 480 - 1'b1)  )
                begin
                    Red       <= Bg_data2[11:8]    ; // ��ɫ����
                    Green     <= Bg_data2[7:4]     ; // ��ɫ����
                    Blue      <= Bg_data2[3:0]      ; // ��ɫ����
                end                
                else
                begin
                    Red <= 4'b0000;  
                    Green <= 4'b0000;  
                    Blue <= 4'b0000; 
                end
            end
            //����
            else
            begin
                if (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH+210)  && 
                     R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH +210+ 220- 1'b1)  &&
                     R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH +160                 )  && 
                     R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH +160+ 160 - 1'b1))//����
                begin
                    Red <=  G_data[11:8];  
                    Green <=  G_data[7:4];  
                    Blue <=  G_data[3:0]; 
                end  
                else
                begin
                    Red <= 4'd0;  
                    Green <= 4'd0;  
                    Blue <= 4'd0; 
                end  
            end
        end 
        else 
        begin
            Red <=  4'd0;
            Green <=  4'd0;
            Blue <=  4'd0 ;
        end          
    end
 
        //ÿ֡���£��ƶ��򣨺Ͱ壩
        always @ (posedge vs )//or posedge rst)  
        begin
                // movement of the bar�ģ�����*/
              if (left && Bar_X >= 0/*C_H_SYNC_PULSE + C_H_BACK_PORCH*/) 
                begin 
                    if(Bar_X < speed)
                        Bar_X <= 0; 
                    else
                        Bar_X <= Bar_X - speed;//1; 
              end  
              else if(right && Bar_X <= C_H_ACTIVE_TIME - Bar_Width)
                begin          
                    Bar_X <= Bar_X + speed;//1; 
              end 
                
                //Ų��
               if (Ball_up == 1) // go up 
                    Ball_Y <= Ball_Y - speed;//Ball_speed;  
               else //go down
                    Ball_Y <= Ball_Y + speed;//Ball_speed;  
               if (Ball_right == 1) // go right 
                    Ball_X <= Ball_X + speed;//Ball_speed;  
               else //go left
                    Ball_X <= Ball_X - speed;//Ball_speed;      
           //end 
           end//always
            
            //ײ���߽�䷽��
           always @ (negedge vs)//or posedge rst)  
           begin
                if(rst)
                    grade <= 0;
                else
                begin
                if (Ball_Y <= C_V_SYNC_PULSE + C_V_BACK_PORCH)   // �ܵ��Ͻ�֮����
                begin    
                    Ball_up <= 0;              // ��Ϊ�½�
                    fail <= 0;
                end
                else if (Ball_Y >= (C_V_SYNC_PULSE + C_V_BACK_PORCH+Bar_Y - Ball_r)&&Ball_Y < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME - Ball_r+1)
                 && Ball_X <= C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X+Bar_Width && Ball_X >= C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X)  
                begin   
                    Ball_up <= 1;  //�ӵ���������
                    grade <= grade+speed;   //��������
                end
                else if (Ball_Y >= (C_V_SYNC_PULSE + C_V_BACK_PORCH+Bar_Y- Ball_r/*+Bar_Height*/))// && Ball_Y < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME - Ball_r+1))
                begin
                    // δ�ӵ�С��
                    fail <= 1;
                end 
                else  
                    Ball_up <= Ball_up;  //����
               
                  
              if (Ball_X <= C_H_SYNC_PULSE + C_H_BACK_PORCH)  
                 Ball_right <= 1;  
              else if (Ball_X >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME)  
                 Ball_right <= 0;  
              else  
                 Ball_right <= Ball_right;  
              end
          end

endmodule
