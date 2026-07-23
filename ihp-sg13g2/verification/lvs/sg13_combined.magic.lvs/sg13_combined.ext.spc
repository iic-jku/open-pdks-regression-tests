* NGSPICE file created from sg13_combined.ext - technology: ihp-sg13g2

.subckt sg13_combined G VDD VSS
X0 a_554_348# G VSS VSS sg13_lv_nmos ad=0.345p pd=2.69u as=0.345p ps=2.69u w=1u l=0.72u
X1 dw_2768_2744# G VSS VSS sg13_hv_nmos ad=0.345p pd=2.69u as=0.345p ps=2.69u w=1u l=0.72u
X2 VSS dw_2768_2744# VSS schottky_nbl1 l=1.2u w=2.655u
X3 VSS a_2910_379# dantenna l=0.78u w=0.78u
X4 a_832_2612# dw_2768_2744# VSS rsil l=0.5u w=0.5u
X5 a_136_2612# a_414_2612# VSS rhigh l=0.96u w=0.5u
X6 a_136_2612# a_554_348# cap_cmim l=20u w=20u
X7 VSS VSS a_2910_379# VSS sg13_hv_nmos ad=0.102p pd=1.28u as=0.102p ps=1.28u w=0.3u l=0.45u
X8 a_2910_379# VDD VDD VDD sg13_hv_pmos ad=0.102p pd=1.28u as=0.102p ps=1.28u w=0.3u l=0.45u
X9 a_136_2612# a_554_348# cap_rfcmim l=10u w=10u
X10 a_414_2612# a_832_2612# VSS rppd l=0.5u w=0.5u
X11 VSS VSS a_2910_379# VSS sg13_lv_nmos ad=0.1005p pd=1.34u as=0.1005p ps=1.34u w=0.15u l=0.45u
X12 a_2910_379# VDD dpantenna l=0.78u w=0.78u
X13 VDD G a_554_348# VDD sg13_lv_pmos ad=0.345p pd=2.69u as=0.345p ps=2.69u w=1u l=0.72u
X14 a_2910_379# VDD VDD VDD sg13_lv_pmos ad=0.1005p pd=1.34u as=0.1005p ps=1.34u w=0.15u l=0.45u
X15 VDD G dw_2768_2744# VDD sg13_hv_pmos ad=0.345p pd=2.69u as=0.345p ps=2.69u w=1u l=0.72u
.ends

