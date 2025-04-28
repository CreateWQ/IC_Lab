
/*
*                                                                                                                       
* This Lab is Super MOSFET Calcualtor.                                                                                  
*                                                                                                                       
* There are 3 input singals, each signal has 3 bits, a total of 6 groups.
* There is also a input signal with 2 bits.
* The output signal is 10 btis wide.
*
* The design includes 3 modules for:
*   - ID/gm calculation
*   - Sorting 
*   - Max/Min calculation.
*
* There are 4 modes for calculating current or transconductance, as follows:                      
*   2'b00 | Smaller transconductance
*   2'b01 | Smaller current
*   2'b10 | Larger  transconductance
*   2'b11 | Larger  current
*                                                                                                                       
* The output signal ranges from 0 to 1023.
*                                                                                                                       
* @author Alex chen                                                                                                     
*                                                                                                                       
* @date 2025-04-28                                                                                                      
*                                                                                                                       
* circuit                                                                                                               
*                                      _______________       _______________       _______________                      
*     {W_0, V_GS_0, V_DS_0} --9 bits-→|               |----→|               |----→|               |                     
*     {W_1, V_GS_1, V_DS_1} --9 bits-→|               |----→|               |----→|               |                     
*     {W_2, V_GS_2, V_DS_2} --9 bits-→|   ID / gm     |----→|    Sorting    |----→|    Max/Min    |--10 bits--→ out_r   
*     {W_3, V_GS_3, V_DS_3} --9 bits-→|  Calculation  |----→|               |----→|  Calculation  |                     
*     {W_4, V_GS_4, V_DS_4} --9 bits-→|               |----→|               |----→|               |                     
*     {W_5, V_GS_5, V_DS_5} --9 bits-→|_______________|----→|_______________|----→|_______________|                     
*                                                                                         ↑
*                                                                                       2 bits
*                                                                                         |
*                                                                                        mode
*
*/

module SMC(
    
    input [2:0] W_0, V_GS_0, V_DS_0,
    input [2:0] W_1, V_GS_1, V_DS_1,
    input [2:0] W_2, V_GS_2, V_DS_2,
    input [2:0] W_3, V_GS_3, V_DS_3,
    input [2:0] W_4, V_GS_4, V_DS_4,
    input [2:0] W_5, V_GS_5, V_DS_5,
    input [1:0] mode,
    output [9:0] out_n

);

genvar idx;
parameter TOTAL_INPUT = 6 ;

wire[2:0] W_[0:TOTAL_INPUT-1];
wire[2:0] V_GS[0:TOTAL_INPUT-1];
wire[2:0] V_DS[0:TOTAL_INPUT-1];

 assign W_[0] = W_0 ;
 assign W_[1] = W_1 ;
 assign W_[2] = W_2 ;
 assign W_[3] = W_3 ;
 assign W_[4] = W_4 ;
 assign W_[5] = W_5 ;
 assign V_GS[0] = V_GS_0 ;
 assign V_GS[1] = V_GS_1 ;
 assign V_GS[2] = V_GS_2 ;
 assign V_GS[3] = V_GS_3 ;
 assign V_GS[4] = V_GS_4 ;
 assign V_GS[5] = V_GS_5 ;
 assign V_DS[0] = V_DS_0 ;
 assign V_DS[1] = V_DS_1 ;
 assign V_DS[2] = V_DS_2 ;
 assign V_DS[3] = V_DS_3 ;
 assign V_DS[4] = V_DS_4 ;
 assign V_DS[5] = V_DS_5 ;


wire[2:0] ID_Tri_A[0:TOTAL_INPUT-1]; 
wire[2:0] ID_Tri_B[0:TOTAL_INPUT-1];
wire[3:0] ID_Tri_C[0:TOTAL_INPUT-1];

wire[2:0] ID_Sat_A[0:TOTAL_INPUT-1];
wire[2:0] ID_Sat_B[0:TOTAL_INPUT-1];
wire[2:0] ID_Sat_C[0:TOTAL_INPUT-1];

wire[2:0] gm_Tri_A[0:TOTAL_INPUT-1];
wire[2:0] gm_Tri_B[0:TOTAL_INPUT-1];
wire[2:0] gm_Tri_C[0:TOTAL_INPUT-1];

wire[2:0] gm_Sat_A[0:TOTAL_INPUT-1];
wire[2:0] gm_Sat_B[0:TOTAL_INPUT-1];
wire[2:0] gm_Sat_C[0:TOTAL_INPUT-1];

generate
    for( idx=0 ; idx < TOTAL_INPUT; idx=idx+1 ) begin
        
        assign ID_Tri_A[idx] = V_DS[idx] ;
        assign ID_Tri_B[idx] = W_[idx] ;
        assign ID_Tri_C[idx] = 2*V_GS[idx] - V_DS[idx] - 2 ;
        
        assign gm_Tri_A[idx] = 2 ;
        assign gm_Tri_B[idx] = W_[idx] ;
        assign gm_Tri_C[idx] = V_DS[idx] ;
        
        assign ID_Sat_A[idx] = W_[idx] ;
        assign ID_Sat_B[idx] = V_GS[idx] - 1 ;
        assign ID_Sat_C[idx] = ID_Sat_B[idx] ;       
        
        assign gm_Sat_A[idx] = 2 ;
        assign gm_Sat_B[idx] = W_[idx] ;
        assign gm_Sat_C[idx] = ID_Sat_B[idx] ;      
    end
endgenerate

wire is_Tri[0:TOTAL_INPUT-1];

generate
    for( idx=0 ; idx< TOTAL_INPUT; idx=idx+1 ) begin
        assign is_Tri[idx] = ( V_GS[idx]>(V_DS[idx]+1) ) ? 1'b1 : 1'b0 ;
    end
endgenerate

wire[2:0] ID_A[0:TOTAL_INPUT-1];
wire[2:0] ID_B[0:TOTAL_INPUT-1];
wire[2:0] gm_A[0:TOTAL_INPUT-1];
wire[2:0] gm_B[0:TOTAL_INPUT-1];
wire[2:0] gm_C[0:TOTAL_INPUT-1];
wire[3:0] ID_C[0:TOTAL_INPUT-1];

generate
    for( idx=0 ; idx< TOTAL_INPUT; idx=idx+1 ) begin
        assign ID_A[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_A[idx] : ID_Sat_A[idx] ;
        assign ID_B[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_B[idx] : ID_Sat_B[idx] ;
        assign ID_C[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_C[idx] : ID_Sat_C[idx] ;
        assign gm_A[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_A[idx] : gm_Sat_A[idx] ;
        assign gm_B[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_B[idx] : gm_Sat_B[idx] ;
        assign gm_C[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_C[idx] : gm_Sat_C[idx] ;
    end
endgenerate

wire[2:0] A[0:TOTAL_INPUT-1];
wire[2:0] B[0:TOTAL_INPUT-1];
wire[3:0] C[0:TOTAL_INPUT-1];

generate
    for( idx=0 ; idx< TOTAL_INPUT; idx=idx+1 ) begin
        assign A[idx] = ( mode[0]==1'b1 ) ? ID_A[idx] : gm_A[idx] ;
        assign B[idx] = ( mode[0]==1'b1 ) ? ID_B[idx] : gm_B[idx] ;
        assign C[idx] = ( mode[0]==1'b1 ) ? ID_C[idx] : gm_C[idx] ;
    end
endgenerate


wire [9:0] cal_out[0:TOTAL_INPUT-1];

generate
    for( idx=0 ; idx<=TOTAL_INPUT-1 ; idx=idx+1 ) begin
        assign cal_out[idx] = ( A[idx] * B[idx] * C[idx] ) / 3 ;
    end
endgenerate


wire[9:0] n[0:TOTAL_INPUT-1]; 

Sorting sort(  
    .in0(cal_out[0]),
    .in1(cal_out[1]),
    .in2(cal_out[2]),
    .in3(cal_out[3]),
    .in4(cal_out[4]),
    .in5(cal_out[5]),
    .out0(n[0]),
    .out1(n[1]),
    .out2(n[2]),
    .out3(n[3]),
    .out4(n[4]),
    .out5(n[5]) 
);

wire[9:0] n1[0:TOTAL_INPUT-1];

assign n1[0] = ( mode[1]==1'b1 ) ? n[0] : n[3] ;
assign n1[1] = ( mode[1]==1'b1 ) ? n[1] : n[4] ;
assign n1[2] = ( mode[1]==1'b1 ) ? n[2] : n[5] ;

wire [9:0] out_0, out_1, out_2;

assign out_0 = ( mode[0]==1'b0 ) ? n1[0] : ( n1[0]<<1 ) + n1[0] ;
assign out_1 = ( mode[0]==1'b0 ) ? n1[1] : ( n1[1]<<2 ) ;
assign out_2 = ( mode[0]==1'b0 ) ? n1[2] : ( n1[2]<<2 ) + n1[2] ;

assign out_n = out_0 + out_1 + out_2 ;

endmodule

/*
*   Sorting network
*                   
*              layer 1      layer 2 layer 3  layer 4  layer 5
*                 ↓            ↓       ↓         ↓       ↓
*      in0 -------●--------------------●---------●------------- out0
*                 |                    |         |             
*      in1 -------|--●---------●-------|---------●-------●----- out1
*                 |  |         |       |                 |      
*      in2 -------|--|--●------●-------|--●------●-------●----- out2
*                 |  |  |              |  |      |              
*      in3 -------|--●--|------●-------●--|------●-------●----- out3
*                 |     |      |          |              |      
*      in4 -------|-----●------●----------|------●-------●----- out4
*                 |                       |      |             
*      in5 -------●-----------------------●------●------------- out5
*
*
*/

module Sorting(
    // input sorting signals
    input[9:0] in0,
    input[9:0] in1,
    input[9:0] in2,
    input[9:0] in3,
    input[9:0] in4,
    input[9:0] in5,
    // output sorted signals
    output[9:0] out0,
    output[9:0] out1,
    output[9:0] out2,
    output[9:0] out3,
    output[9:0] out4,
    output[9:0] out5
);
    
    wire[9:0] layer1[5:0];
    wire[9:0] layer2[5:0];
    wire[9:0] layer3[5:0];
    wire[9:0] layer4[5:0];

    assign layer1[0] = in0 < in5 ? in5 : in0;
    assign layer1[1] = in1 < in3 ? in3 : in1;
    assign layer1[2] = in2 < in4 ? in4 : in2;
    assign layer1[3] = in1 < in3 ? in1 : in3;
    assign layer1[4] = in2 < in4 ? in2 : in4;
    assign layer1[5] = in0 < in5 ? in0 : in5;

    assign layer2[0] =                                     layer1[0];
    assign layer2[1] = layer1[1] < layer1[2] ? layer1[2] : layer1[1];
    assign layer2[2] = layer1[1] < layer1[2] ? layer1[1] : layer1[2];
    assign layer2[3] = layer1[3] < layer1[4] ? layer1[4] : layer1[3];
    assign layer2[4] = layer1[3] < layer1[4] ? layer1[3] : layer1[4];
    assign layer2[5] =                                     layer1[5];

    assign layer3[0] = layer2[0] < layer2[3] ? layer2[3] : layer2[0];
    assign layer3[1] =                                     layer2[1];
    assign layer3[2] = layer2[2] < layer2[5] ? layer2[5] : layer2[2];
    assign layer3[3] = layer2[0] < layer2[3] ? layer2[0] : layer2[3];
    assign layer3[4] =                                     layer2[4];
    assign layer3[5] = layer2[2] < layer2[5] ? layer2[2] : layer2[5];

    assign layer4[0] = layer3[0] < layer3[1] ? layer3[1] : layer3[0];
    assign layer4[1] = layer3[0] < layer3[1] ? layer3[0] : layer3[1];
    assign layer4[2] = layer3[2] < layer3[3] ? layer3[3] : layer3[2];
    assign layer4[3] = layer3[2] < layer3[3] ? layer3[2] : layer3[3];
    assign layer4[4] = layer3[4] < layer3[5] ? layer3[5] : layer3[4];
    assign layer4[5] = layer3[4] < layer3[5] ? layer3[4] : layer3[5];

    assign out0 =                                     layer4[0];
    assign out1 = layer4[1] < layer4[2] ? layer4[2] : layer4[1];
    assign out2 = layer4[1] < layer4[2] ? layer4[1] : layer4[2];
    assign out3 = layer4[3] < layer4[4] ? layer4[4] : layer4[3];
    assign out4 = layer4[3] < layer4[4] ? layer4[3] : layer4[4];
    assign out5 =                                     layer4[5];

endmodule
