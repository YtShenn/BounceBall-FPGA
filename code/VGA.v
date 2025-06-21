`timescale 1ns / 1ps

module VGA(
    input clk, //输入时钟，100MHz
    input rst , // 系统复位
    input right, //挡板右移，高电平有效
    input left, //挡板左移，高电平有效
    input [7:0] speed, //板移动速度
    output hs, //VGA行同步信号
    output vs, //VGA场同步信号
    output reg [3:0] Red,
    output reg [3:0] Green,
    output reg [3:0] Blue,
    output lose, //游戏失败信号，没能成功挡住球的话就会触发一个高电平脉冲，用于数码管计数   
    output reg [15:0] grade = 0//得分
    );
    //initial fail<=0;
    reg fail=0;
    assign lose=fail;
    // 分辨率为640*480时行时序各个参数定义
    parameter C_H_SYNC_PULSE=96, 
               C_H_BACK_PORCH=48,
               C_H_ACTIVE_TIME=640,
               C_H_FRONT_PORCH=16,
               C_H_LINE_PERIOD= 800;
    // 分辨率为640*480时场时序各个参数定义               
    parameter C_V_SYNC_PULSE=2, 
                C_V_BACK_PORCH=33,
                C_V_ACTIVE_TIME=480,
                C_V_FRONT_PORCH=10,
                C_V_FRAME_PERIOD=525;
                    
    parameter Ball_r = 25; //待修改
    parameter Bar_Width = 165; 
    parameter Bar_Height = 25;
    
    reg [11:0] R_h_cnt; // 行时序计数器
    reg [11:0] R_v_cnt; // 列时序计数器
    reg R_clk_25M; // 25MHz的像素时钟
    
    reg [9:0] Ball_X = C_H_SYNC_PULSE + C_H_BACK_PORCH + 0;
    reg [9:0] Ball_Y = C_V_SYNC_PULSE + C_V_BACK_PORCH + 0;
    //reg [3:0]Ball_speed =speed;//球速度，考虑后期通过难度改变对应改变速度大小
    reg Ball_up = 1 ;//球向上走
    reg Ball_right = 1 ;//球向右走
    
    reg [9:0] Bar_X = 0;//板最左
    reg [9:0] Bar_Y = C_V_ACTIVE_TIME - Bar_Height;//板最上
   
    wire [17:0] Bg_addr1 ; //背景地址1
    wire [17:0] Bg_addr2; //背景地址2
    wire [11:0] Bg_data1; // 数据 1
    wire [11:0] Bg_data2; // 数据 2
    assign Bg_addr1 = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH)*320;
    assign Bg_addr2 = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH - 320) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH)*320;
    reg Bg_PIX_NUM = 640 * 480 ;
    
    wire [16:0] G_addr; //游戏失败背景地址
    wire [11:0] G_data; // 数据 
    assign G_addr = (R_h_cnt - C_H_SYNC_PULSE - C_H_BACK_PORCH - 210) + (R_v_cnt - C_V_SYNC_PULSE - C_V_BACK_PORCH - 160)*220;
    
    wire active_flag = (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH))  &&
                            (R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME))  && 
                            (R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH))  &&
                            (R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME)) ; // 激活标志，当这个信号为1时RGB的数据可以显示在屏幕上
     //rom
    bg1_rom bg1(clk,Bg_addr1,Bg_data1);
    bg2_rom bg2(clk,Bg_addr2,Bg_data2);
    go_rom go(clk,G_addr,G_data);
    
    reg count = 1'b0;
    //产生25MHz的像素时钟
    always @(posedge clk or posedge rst)
    begin
        if(rst)//高电平有效
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
    // 产生行时序
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
    // 产生场时序
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
   
    // 功能：把ROM里面的图片数据输出
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
                begin  //显示小球
                    Red   <=  4'b1111; // 黄色小球
                    Green <=  4'b1111; 
                    Blue  <=  4'b0000;  
                end  
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X)  && 
                                 R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X + Bar_Width  - 1'b1)  &&
                                 R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH + Bar_Y                        )  && 
                                 R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + Bar_Y + Bar_Height - 1'b1)  )//显示板子,待改
                begin//棕色木板
                    Red <=  4'b1011;  
                    Green <=  4'b1000;  
                    Blue <=  4'b0101;
                end                
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH )  && 
                   R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 320  - 1'b1)  &&
                   R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                        )  && 
                   R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + 480 - 1'b1)  )
                begin
                    Red       <= Bg_data1[11:8]    ; // 红色分量
                    Green     <= Bg_data1[7:4]     ; // 绿色分量
                    Blue      <= Bg_data1[3:0]      ; // 蓝色分量
                end
                else if(R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 320 )  && 
                        R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + 640  - 1'b1)  &&
                        R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                        )  && 
                        R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + 480 - 1'b1)  )
                begin
                    Red       <= Bg_data2[11:8]    ; // 红色分量
                    Green     <= Bg_data2[7:4]     ; // 绿色分量
                    Blue      <= Bg_data2[3:0]      ; // 蓝色分量
                end                
                else
                begin
                    Red <= 4'b0000;  
                    Green <= 4'b0000;  
                    Blue <= 4'b0000; 
                end
            end
            //输了
            else
            begin
                if (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH+210)  && 
                     R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH +210+ 220- 1'b1)  &&
                     R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH +160                 )  && 
                     R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH +160+ 160 - 1'b1))//背景
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
 
        //每帧更新，移动球（和板）
        always @ (posedge vs )//or posedge rst)  
        begin
                // movement of the bar改！！！*/
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
                
                //挪球
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
            
            //撞到边界变方向
           always @ (negedge vs)//or posedge rst)  
           begin
                if(rst)
                    grade <= 0;
                else
                begin
                if (Ball_Y <= C_V_SYNC_PULSE + C_V_BACK_PORCH)   // 跑到上界之外了
                begin    
                    Ball_up <= 0;              // 变为下降
                    fail <= 0;
                end
                else if (Ball_Y >= (C_V_SYNC_PULSE + C_V_BACK_PORCH+Bar_Y - Ball_r)&&Ball_Y < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME - Ball_r+1)
                 && Ball_X <= C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X+Bar_Width && Ball_X >= C_H_SYNC_PULSE + C_H_BACK_PORCH + Bar_X)  
                begin   
                    Ball_up <= 1;  //接到球，往上走
                    grade <= grade+speed;   //积分增加
                end
                else if (Ball_Y >= (C_V_SYNC_PULSE + C_V_BACK_PORCH+Bar_Y- Ball_r/*+Bar_Height*/))// && Ball_Y < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME - Ball_r+1))
                begin
                    // 未接到小球
                    fail <= 1;
                end 
                else  
                    Ball_up <= Ball_up;  //不变
               
                  
              if (Ball_X <= C_H_SYNC_PULSE + C_H_BACK_PORCH)  
                 Ball_right <= 1;  
              else if (Ball_X >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME)  
                 Ball_right <= 0;  
              else  
                 Ball_right <= Ball_right;  
              end
          end

endmodule
