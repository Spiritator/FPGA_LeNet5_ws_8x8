`timescale 1ns / 1ps


module systolic_pe_array(clk,rst,load_wght,ifmap0,ifmap1,ifmap2,ifmap3,ifmap4,ifmap5,ifmap6,ifmap7,wght0,wght1,wght2,wght3,wght4,wght5,wght6,wght7,sum_in0,sum_in1,sum_in2,sum_in3,sum_in4,sum_in5,sum_in6,sum_in7,accum0,accum1,accum2,accum3,accum4,accum5,accum6,accum7);

parameter wd=8,in=4,fi=3;

input clk,rst,load_wght;
input signed [wd-1:0] ifmap0,ifmap1,ifmap2,ifmap3,ifmap4,ifmap5,ifmap6,ifmap7;
input signed [wd-1:0] wght0,wght1,wght2,wght3,wght4,wght5,wght6,wght7;
input signed [2*wd-1:0] sum_in0,sum_in1,sum_in2,sum_in3,sum_in4,sum_in5,sum_in6,sum_in7;
output signed [2*wd-1:0] accum0,accum1,accum2,accum3,accum4,accum5,accum6,accum7;

wire signed [wd-1:0] ifmap_tl0,ifmap_tl1,ifmap_tl2,ifmap_tl3,ifmap_tl4,ifmap_tl5,ifmap_tl6,ifmap_tl7;

wire signed [wd-1:0] ifmap_w00,ifmap_w01,ifmap_w02,ifmap_w03,ifmap_w04,ifmap_w05,ifmap_w06,ifmap_w07;
wire signed [wd-1:0] ifmap_w10,ifmap_w11,ifmap_w12,ifmap_w13,ifmap_w14,ifmap_w15,ifmap_w16,ifmap_w17;
wire signed [wd-1:0] ifmap_w20,ifmap_w21,ifmap_w22,ifmap_w23,ifmap_w24,ifmap_w25,ifmap_w26,ifmap_w27;
wire signed [wd-1:0] ifmap_w30,ifmap_w31,ifmap_w32,ifmap_w33,ifmap_w34,ifmap_w35,ifmap_w36,ifmap_w37;
wire signed [wd-1:0] ifmap_w40,ifmap_w41,ifmap_w42,ifmap_w43,ifmap_w44,ifmap_w45,ifmap_w46,ifmap_w47;
wire signed [wd-1:0] ifmap_w50,ifmap_w51,ifmap_w52,ifmap_w53,ifmap_w54,ifmap_w55,ifmap_w56,ifmap_w57;
wire signed [wd-1:0] ifmap_w60,ifmap_w61,ifmap_w62,ifmap_w63,ifmap_w64,ifmap_w65,ifmap_w66,ifmap_w67;
wire signed [wd-1:0] ifmap_w70,ifmap_w71,ifmap_w72,ifmap_w73,ifmap_w74,ifmap_w75,ifmap_w76,ifmap_w77;

wire signed [wd-1:0] wght_w00,wght_w01,wght_w02,wght_w03,wght_w04,wght_w05,wght_w06,wght_w07;
wire signed [wd-1:0] wght_w10,wght_w11,wght_w12,wght_w13,wght_w14,wght_w15,wght_w16,wght_w17;
wire signed [wd-1:0] wght_w20,wght_w21,wght_w22,wght_w23,wght_w24,wght_w25,wght_w26,wght_w27;
wire signed [wd-1:0] wght_w30,wght_w31,wght_w32,wght_w33,wght_w34,wght_w35,wght_w36,wght_w37;
wire signed [wd-1:0] wght_w40,wght_w41,wght_w42,wght_w43,wght_w44,wght_w45,wght_w46,wght_w47;
wire signed [wd-1:0] wght_w50,wght_w51,wght_w52,wght_w53,wght_w54,wght_w55,wght_w56,wght_w57;
wire signed [wd-1:0] wght_w60,wght_w61,wght_w62,wght_w63,wght_w64,wght_w65,wght_w66,wght_w67;
wire signed [wd-1:0] wght_w70,wght_w71,wght_w72,wght_w73,wght_w74,wght_w75,wght_w76,wght_w77;

wire signed [2*wd-1:0] psum_tl0,psum_tl1,psum_tl2,psum_tl3,psum_tl4,psum_tl5,psum_tl6,psum_tl7;
reg signed [2*wd-1:0] psum_bf0,psum_bf1,psum_bf2,psum_bf3,psum_bf4,psum_bf5,psum_bf6,psum_bf7;

wire signed [2*wd-1:0] psum_w00,psum_w01,psum_w02,psum_w03,psum_w04,psum_w05,psum_w06,psum_w07;
wire signed [2*wd-1:0] psum_w10,psum_w11,psum_w12,psum_w13,psum_w14,psum_w15,psum_w16,psum_w17;
wire signed [2*wd-1:0] psum_w20,psum_w21,psum_w22,psum_w23,psum_w24,psum_w25,psum_w26,psum_w27;
wire signed [2*wd-1:0] psum_w30,psum_w31,psum_w32,psum_w33,psum_w34,psum_w35,psum_w36,psum_w37;
wire signed [2*wd-1:0] psum_w40,psum_w41,psum_w42,psum_w43,psum_w44,psum_w45,psum_w46,psum_w47;
wire signed [2*wd-1:0] psum_w50,psum_w51,psum_w52,psum_w53,psum_w54,psum_w55,psum_w56,psum_w57;
wire signed [2*wd-1:0] psum_w60,psum_w61,psum_w62,psum_w63,psum_w64,psum_w65,psum_w66,psum_w67;
wire signed [2*wd-1:0] psum_w70,psum_w71,psum_w72,psum_w73,psum_w74,psum_w75,psum_w76,psum_w77;

mac_unit mac00(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl0),.wght_in(wght0),   .psum_in(psum_bf0),.ifmap_out(ifmap_w00),.wght_out(wght_w00),.psum_out(psum_w00));
mac_unit mac01(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl1),.wght_in(wght_w00),.psum_in(psum_w00),.ifmap_out(ifmap_w01),.wght_out(wght_w01),.psum_out(psum_w01));
mac_unit mac02(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl2),.wght_in(wght_w01),.psum_in(psum_w01),.ifmap_out(ifmap_w02),.wght_out(wght_w02),.psum_out(psum_w02));
mac_unit mac03(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl3),.wght_in(wght_w02),.psum_in(psum_w02),.ifmap_out(ifmap_w03),.wght_out(wght_w03),.psum_out(psum_w03));
mac_unit mac04(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl4),.wght_in(wght_w03),.psum_in(psum_w03),.ifmap_out(ifmap_w04),.wght_out(wght_w04),.psum_out(psum_w04));
mac_unit mac05(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl5),.wght_in(wght_w04),.psum_in(psum_w04),.ifmap_out(ifmap_w05),.wght_out(wght_w05),.psum_out(psum_w05));
mac_unit mac06(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl6),.wght_in(wght_w05),.psum_in(psum_w05),.ifmap_out(ifmap_w06),.wght_out(wght_w06),.psum_out(psum_w06));
mac_unit mac07(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_tl7),.wght_in(wght_w06),.psum_in(psum_w06),.ifmap_out(ifmap_w07),.wght_out(wght_w07),.psum_out(psum_w07));

mac_unit mac10(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w00),.wght_in(wght1),   .psum_in(psum_bf1),.ifmap_out(ifmap_w10),.wght_out(wght_w10),.psum_out(psum_w10));
mac_unit mac11(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w01),.wght_in(wght_w10),.psum_in(psum_w10),.ifmap_out(ifmap_w11),.wght_out(wght_w11),.psum_out(psum_w11));
mac_unit mac12(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w02),.wght_in(wght_w11),.psum_in(psum_w11),.ifmap_out(ifmap_w12),.wght_out(wght_w12),.psum_out(psum_w12));
mac_unit mac13(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w03),.wght_in(wght_w12),.psum_in(psum_w12),.ifmap_out(ifmap_w13),.wght_out(wght_w13),.psum_out(psum_w13));
mac_unit mac14(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w04),.wght_in(wght_w13),.psum_in(psum_w13),.ifmap_out(ifmap_w14),.wght_out(wght_w14),.psum_out(psum_w14));
mac_unit mac15(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w05),.wght_in(wght_w14),.psum_in(psum_w14),.ifmap_out(ifmap_w15),.wght_out(wght_w15),.psum_out(psum_w15));
mac_unit mac16(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w06),.wght_in(wght_w15),.psum_in(psum_w15),.ifmap_out(ifmap_w16),.wght_out(wght_w16),.psum_out(psum_w16));
mac_unit mac17(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w07),.wght_in(wght_w16),.psum_in(psum_w16),.ifmap_out(ifmap_w17),.wght_out(wght_w17),.psum_out(psum_w17));

mac_unit mac20(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w10),.wght_in(wght2),   .psum_in(psum_bf2),.ifmap_out(ifmap_w20),.wght_out(wght_w20),.psum_out(psum_w20));
mac_unit mac21(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w11),.wght_in(wght_w20),.psum_in(psum_w20),.ifmap_out(ifmap_w21),.wght_out(wght_w21),.psum_out(psum_w21));
mac_unit mac22(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w12),.wght_in(wght_w21),.psum_in(psum_w21),.ifmap_out(ifmap_w22),.wght_out(wght_w22),.psum_out(psum_w22));
mac_unit mac23(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w13),.wght_in(wght_w22),.psum_in(psum_w22),.ifmap_out(ifmap_w23),.wght_out(wght_w23),.psum_out(psum_w23));
mac_unit mac24(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w14),.wght_in(wght_w23),.psum_in(psum_w23),.ifmap_out(ifmap_w24),.wght_out(wght_w24),.psum_out(psum_w24));
mac_unit mac25(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w15),.wght_in(wght_w24),.psum_in(psum_w24),.ifmap_out(ifmap_w25),.wght_out(wght_w25),.psum_out(psum_w25));
mac_unit mac26(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w16),.wght_in(wght_w25),.psum_in(psum_w25),.ifmap_out(ifmap_w26),.wght_out(wght_w26),.psum_out(psum_w26));
mac_unit mac27(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w17),.wght_in(wght_w26),.psum_in(psum_w26),.ifmap_out(ifmap_w27),.wght_out(wght_w27),.psum_out(psum_w27));

mac_unit mac30(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w20),.wght_in(wght3),   .psum_in(psum_bf3),.ifmap_out(ifmap_w30),.wght_out(wght_w30),.psum_out(psum_w30));
mac_unit mac31(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w21),.wght_in(wght_w30),.psum_in(psum_w30),.ifmap_out(ifmap_w31),.wght_out(wght_w31),.psum_out(psum_w31));
mac_unit mac32(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w22),.wght_in(wght_w31),.psum_in(psum_w31),.ifmap_out(ifmap_w32),.wght_out(wght_w32),.psum_out(psum_w32));
mac_unit mac33(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w23),.wght_in(wght_w32),.psum_in(psum_w32),.ifmap_out(ifmap_w33),.wght_out(wght_w33),.psum_out(psum_w33));
mac_unit mac34(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w24),.wght_in(wght_w33),.psum_in(psum_w33),.ifmap_out(ifmap_w34),.wght_out(wght_w34),.psum_out(psum_w34));
mac_unit mac35(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w25),.wght_in(wght_w34),.psum_in(psum_w34),.ifmap_out(ifmap_w35),.wght_out(wght_w35),.psum_out(psum_w35));
mac_unit mac36(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w26),.wght_in(wght_w35),.psum_in(psum_w35),.ifmap_out(ifmap_w36),.wght_out(wght_w36),.psum_out(psum_w36));
mac_unit mac37(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w27),.wght_in(wght_w36),.psum_in(psum_w36),.ifmap_out(ifmap_w37),.wght_out(wght_w37),.psum_out(psum_w37));

mac_unit mac40(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w30),.wght_in(wght4),   .psum_in(psum_bf4),.ifmap_out(ifmap_w40),.wght_out(wght_w40),.psum_out(psum_w40));
mac_unit mac41(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w31),.wght_in(wght_w40),.psum_in(psum_w40),.ifmap_out(ifmap_w41),.wght_out(wght_w41),.psum_out(psum_w41));
mac_unit mac42(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w32),.wght_in(wght_w41),.psum_in(psum_w41),.ifmap_out(ifmap_w42),.wght_out(wght_w42),.psum_out(psum_w42));
mac_unit mac43(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w33),.wght_in(wght_w42),.psum_in(psum_w42),.ifmap_out(ifmap_w43),.wght_out(wght_w43),.psum_out(psum_w43));
mac_unit mac44(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w34),.wght_in(wght_w43),.psum_in(psum_w43),.ifmap_out(ifmap_w44),.wght_out(wght_w44),.psum_out(psum_w44));
mac_unit mac45(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w35),.wght_in(wght_w44),.psum_in(psum_w44),.ifmap_out(ifmap_w45),.wght_out(wght_w45),.psum_out(psum_w45));
mac_unit mac46(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w36),.wght_in(wght_w45),.psum_in(psum_w45),.ifmap_out(ifmap_w46),.wght_out(wght_w46),.psum_out(psum_w46));
mac_unit mac47(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w37),.wght_in(wght_w46),.psum_in(psum_w46),.ifmap_out(ifmap_w47),.wght_out(wght_w47),.psum_out(psum_w47));

mac_unit mac50(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w40),.wght_in(wght5),   .psum_in(psum_bf5),.ifmap_out(ifmap_w50),.wght_out(wght_w50),.psum_out(psum_w50));
mac_unit mac51(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w41),.wght_in(wght_w50),.psum_in(psum_w50),.ifmap_out(ifmap_w51),.wght_out(wght_w51),.psum_out(psum_w51));
mac_unit mac52(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w42),.wght_in(wght_w51),.psum_in(psum_w51),.ifmap_out(ifmap_w52),.wght_out(wght_w52),.psum_out(psum_w52));
mac_unit mac53(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w43),.wght_in(wght_w52),.psum_in(psum_w52),.ifmap_out(ifmap_w53),.wght_out(wght_w53),.psum_out(psum_w53));
mac_unit mac54(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w44),.wght_in(wght_w53),.psum_in(psum_w53),.ifmap_out(ifmap_w54),.wght_out(wght_w54),.psum_out(psum_w54));
mac_unit mac55(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w45),.wght_in(wght_w54),.psum_in(psum_w54),.ifmap_out(ifmap_w55),.wght_out(wght_w55),.psum_out(psum_w55));
mac_unit mac56(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w46),.wght_in(wght_w55),.psum_in(psum_w55),.ifmap_out(ifmap_w56),.wght_out(wght_w56),.psum_out(psum_w56));
mac_unit mac57(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w47),.wght_in(wght_w56),.psum_in(psum_w56),.ifmap_out(ifmap_w57),.wght_out(wght_w57),.psum_out(psum_w57));

mac_unit mac60(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w50),.wght_in(wght6),   .psum_in(psum_bf6),.ifmap_out(ifmap_w60),.wght_out(wght_w60),.psum_out(psum_w60));
mac_unit mac61(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w51),.wght_in(wght_w60),.psum_in(psum_w60),.ifmap_out(ifmap_w61),.wght_out(wght_w61),.psum_out(psum_w61));
mac_unit mac62(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w52),.wght_in(wght_w61),.psum_in(psum_w61),.ifmap_out(ifmap_w62),.wght_out(wght_w62),.psum_out(psum_w62));
mac_unit mac63(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w53),.wght_in(wght_w62),.psum_in(psum_w62),.ifmap_out(ifmap_w63),.wght_out(wght_w63),.psum_out(psum_w63));
mac_unit mac64(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w54),.wght_in(wght_w63),.psum_in(psum_w63),.ifmap_out(ifmap_w64),.wght_out(wght_w64),.psum_out(psum_w64));
mac_unit mac65(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w55),.wght_in(wght_w64),.psum_in(psum_w64),.ifmap_out(ifmap_w65),.wght_out(wght_w65),.psum_out(psum_w65));
mac_unit mac66(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w56),.wght_in(wght_w65),.psum_in(psum_w65),.ifmap_out(ifmap_w66),.wght_out(wght_w66),.psum_out(psum_w66));
mac_unit mac67(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w57),.wght_in(wght_w66),.psum_in(psum_w66),.ifmap_out(ifmap_w67),.wght_out(wght_w67),.psum_out(psum_w67));

mac_unit mac70(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w60),.wght_in(wght7),   .psum_in(psum_bf7),.ifmap_out(ifmap_w70),.wght_out(wght_w70),.psum_out(psum_w70));
mac_unit mac71(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w61),.wght_in(wght_w70),.psum_in(psum_w70),.ifmap_out(ifmap_w71),.wght_out(wght_w71),.psum_out(psum_w71));
mac_unit mac72(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w62),.wght_in(wght_w71),.psum_in(psum_w71),.ifmap_out(ifmap_w72),.wght_out(wght_w72),.psum_out(psum_w72));
mac_unit mac73(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w63),.wght_in(wght_w72),.psum_in(psum_w72),.ifmap_out(ifmap_w73),.wght_out(wght_w73),.psum_out(psum_w73));
mac_unit mac74(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w64),.wght_in(wght_w73),.psum_in(psum_w73),.ifmap_out(ifmap_w74),.wght_out(wght_w74),.psum_out(psum_w74));
mac_unit mac75(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w65),.wght_in(wght_w74),.psum_in(psum_w74),.ifmap_out(ifmap_w75),.wght_out(wght_w75),.psum_out(psum_w75));
mac_unit mac76(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w66),.wght_in(wght_w75),.psum_in(psum_w75),.ifmap_out(ifmap_w76),.wght_out(wght_w76),.psum_out(psum_w76));
mac_unit mac77(.clk(clk),.rst(rst),.load_wght(load_wght),.ifmap_in(ifmap_w67),.wght_in(wght_w76),.psum_in(psum_w76),.ifmap_out(ifmap_w77),.wght_out(wght_w77),.psum_out(psum_w77));


tilting_registers #(.wl(wd)) tilt_in(.clk(clk),.rst(rst),.D0_in(ifmap0),.D1_in(ifmap1),.D2_in(ifmap2),.D3_in(ifmap3),.D4_in(ifmap4),.D5_in(ifmap5),.D6_in(ifmap6),.D7_in(ifmap7),.D0_out(ifmap_tl0),.D1_out(ifmap_tl1),.D2_out(ifmap_tl2),.D3_out(ifmap_tl3),.D4_out(ifmap_tl4),.D5_out(ifmap_tl5),.D6_out(ifmap_tl6),.D7_out(ifmap_tl7));
tilting_registers #(.wl(2*wd)) tilt_out(.clk(clk),.rst(rst),.D0_in(psum_w77),.D1_in(psum_w67),.D2_in(psum_w57),.D3_in(psum_w47),.D4_in(psum_w37),.D5_in(psum_w27),.D6_in(psum_w17),.D7_in(psum_w07),.D0_out(accum7),.D1_out(accum6),.D2_out(accum5),.D3_out(accum4),.D4_out(accum3),.D5_out(accum2),.D6_out(accum1),.D7_out(accum0));
tilting_registers #(.wl(2*wd)) tilt_sumin(.clk(clk),.rst(rst),.D0_in(sum_in0),.D1_in(sum_in1),.D2_in(sum_in2),.D3_in(sum_in3),.D4_in(sum_in4),.D5_in(sum_in5),.D6_in(sum_in6),.D7_in(sum_in7),.D0_out(psum_tl0),.D1_out(psum_tl1),.D2_out(psum_tl2),.D3_out(psum_tl3),.D4_out(psum_tl4),.D5_out(psum_tl5),.D6_out(psum_tl6),.D7_out(psum_tl7));

always @(posedge clk) 
begin
    psum_bf0<=psum_tl0;
    psum_bf1<=psum_tl1;
    psum_bf2<=psum_tl2;
    psum_bf3<=psum_tl3;
    psum_bf4<=psum_tl4;
    psum_bf5<=psum_tl5;
    psum_bf6<=psum_tl6;
    psum_bf7<=psum_tl7;
end

endmodule
