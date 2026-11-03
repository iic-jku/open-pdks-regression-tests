v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -730 440 -730 {lab=net1}
N 380 -700 360 -700 {lab=G}
N 420 -670 440 -670 {lab=VSS}
N 420 -700 440 -700 {lab=VSS}
N 660 -670 680 -670 {lab=net1}
N 620 -700 600 -700 {lab=G}
N 660 -730 680 -730 {lab=VDD}
N 660 -700 680 -700 {lab=VDD}
N 900 -730 920 -730 {lab=net3}
N 860 -700 840 -700 {lab=G}
N 900 -670 920 -670 {lab=VSS}
N 900 -700 920 -700 {lab=VSS}
N 1140 -670 1160 -670 {lab=net3}
N 1100 -700 1080 -700 {lab=G}
N 1140 -730 1160 -730 {lab=VDD}
N 1140 -700 1160 -700 {lab=VDD}
N 1380 -730 1400 -730 {lab=net2}
N 1340 -700 1320 -700 {lab=VSS}
N 1380 -670 1400 -670 {lab=VSS}
N 1380 -700 1400 -700 {lab=VSS}
N 1620 -670 1640 -670 {lab=net2}
N 1580 -700 1560 -700 {lab=VDD}
N 1620 -730 1640 -730 {lab=VDD}
N 1620 -700 1640 -700 {lab=VDD}
N 420 -490 440 -490 {lab=net2}
N 380 -460 360 -460 {lab=VSS}
N 420 -430 440 -430 {lab=VSS}
N 420 -460 440 -460 {lab=VSS}
N 640 -430 640 -410 {lab=VSS}
N 640 -490 640 -510 {lab=net2}
N 880 -430 880 -410 {lab=net2}
N 880 -490 880 -510 {lab=VDD}
N 1120 -430 1120 -410 {lab=net6}
N 1120 -490 1120 -510 {lab=net3}
N 1360 -430 1360 -410 {lab=net5}
N 1360 -490 1360 -510 {lab=net6}
N 1340 -460 1320 -460 {lab=VSS}
N 1600 -430 1600 -410 {lab=net4}
N 1600 -490 1600 -510 {lab=net5}
N 1580 -460 1560 -460 {lab=VSS}
N 400 -250 400 -270 {lab=net4}
N 400 -190 400 -170 {lab=net1}
N 640 -250 640 -270 {lab=net1}
N 640 -190 640 -170 {lab=VDD}
N 600 -200 580 -200 {lab=VSS}
N 900 -250 920 -250 {lab=VDD}
N 860 -220 840 -220 {lab=net2}
N 900 -190 920 -190 {lab=VSS}
N 900 -220 920 -220 {lab=VSS}
N 1140 -250 1160 -250 {lab=net2}
N 1100 -220 1080 -220 {lab=VSS}
N 1140 -190 1160 -190 {lab=VSS}
N 1140 -220 1160 -220 {lab=VSS}
N 160 -700 200 -700 {lab=VDD}
N 160 -660 200 -660 {lab=VSS}
N 160 -620 200 -620 {lab=G}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/nfet_01v8.sym} 400 -700 0 0 {name=M1
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {lab_pin.sym} 440 -730 0 0 {name=l0_D sig_type=std_logic lab=net1}
C {lab_pin.sym} 360 -700 2 0 {name=l0_G sig_type=std_logic lab=G}
C {lab_pin.sym} 440 -670 0 0 {name=l0_S sig_type=std_logic lab=VSS}
C {lab_pin.sym} 440 -700 0 0 {name=l0_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/pfet_01v8.sym} 640 -700 0 0 {name=M2
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {lab_pin.sym} 680 -670 0 0 {name=l1_D sig_type=std_logic lab=net1}
C {lab_pin.sym} 600 -700 2 0 {name=l1_G sig_type=std_logic lab=G}
C {lab_pin.sym} 680 -730 0 0 {name=l1_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 680 -700 0 0 {name=l1_B sig_type=std_logic lab=VDD}
C {sky130_fd_pr/nfet_g5v0d10v5.sym} 880 -700 0 0 {name=M3
W=0.42
L=0.5
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_g5v0d10v5
spiceprefix=X
}
C {lab_pin.sym} 920 -730 0 0 {name=l2_D sig_type=std_logic lab=net3}
C {lab_pin.sym} 840 -700 2 0 {name=l2_G sig_type=std_logic lab=G}
C {lab_pin.sym} 920 -670 0 0 {name=l2_S sig_type=std_logic lab=VSS}
C {lab_pin.sym} 920 -700 0 0 {name=l2_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/pfet_g5v0d10v5.sym} 1120 -700 0 0 {name=M4
W=0.42
L=0.5
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_g5v0d10v5
spiceprefix=X
}
C {lab_pin.sym} 1160 -670 0 0 {name=l3_D sig_type=std_logic lab=net3}
C {lab_pin.sym} 1080 -700 2 0 {name=l3_G sig_type=std_logic lab=G}
C {lab_pin.sym} 1160 -730 0 0 {name=l3_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1160 -700 0 0 {name=l3_B sig_type=std_logic lab=VDD}
C {sky130_fd_pr/nfet_01v8_lvt.sym} 1360 -700 0 0 {name=M5
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_01v8_lvt
spiceprefix=X
}
C {lab_pin.sym} 1400 -730 0 0 {name=l4_D sig_type=std_logic lab=net2}
C {lab_pin.sym} 1320 -700 2 0 {name=l4_G sig_type=std_logic lab=VSS}
C {lab_pin.sym} 1400 -670 0 0 {name=l4_S sig_type=std_logic lab=VSS}
C {lab_pin.sym} 1400 -700 0 0 {name=l4_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/pfet_01v8_hvt.sym} 1600 -700 0 0 {name=M6
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_01v8_hvt
spiceprefix=X
}
C {lab_pin.sym} 1640 -670 0 0 {name=l5_D sig_type=std_logic lab=net2}
C {lab_pin.sym} 1560 -700 2 0 {name=l5_G sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1640 -730 0 0 {name=l5_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1640 -700 0 0 {name=l5_B sig_type=std_logic lab=VDD}
C {sky130_fd_pr/nfet_03v3_nvt.sym} 400 -460 0 0 {name=M7
W=0.42
L=0.5
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_03v3_nvt
spiceprefix=X
}
C {lab_pin.sym} 440 -490 0 0 {name=l6_D sig_type=std_logic lab=net2}
C {lab_pin.sym} 360 -460 2 0 {name=l6_G sig_type=std_logic lab=VSS}
C {lab_pin.sym} 440 -430 0 0 {name=l6_S sig_type=std_logic lab=VSS}
C {lab_pin.sym} 440 -460 0 0 {name=l6_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/diode.sym} 640 -460 0 0 {name=D1
model=diode_pw2nd_05v5
area=2.025e+11
perim=1.8e+06
spiceprefix=X
}
C {lab_pin.sym} 640 -410 1 0 {name=l7_d0 sig_type=std_logic lab=VSS}
C {lab_pin.sym} 640 -510 3 0 {name=l7_d1 sig_type=std_logic lab=net2}
C {sky130_fd_pr/diode.sym} 880 -460 0 0 {name=D2
model=diode_pd2nw_05v5
area=2.025e+11
perim=1.8e+06
spiceprefix=X
}
C {lab_pin.sym} 880 -410 1 0 {name=l8_d0 sig_type=std_logic lab=net2}
C {lab_pin.sym} 880 -510 3 0 {name=l8_d1 sig_type=std_logic lab=VDD}
C {sky130_fd_pr/res_generic_po.sym} 1120 -460 0 0 {name=R1
W=0.33
L=1.65
model=res_generic_po
spiceprefix=X
mult=1
}
C {lab_pin.sym} 1120 -410 1 0 {name=l9_M sig_type=std_logic lab=net6}
C {lab_pin.sym} 1120 -510 3 0 {name=l9_P sig_type=std_logic lab=net3}
C {sky130_fd_pr/res_high_po_0p35.sym} 1360 -460 0 0 {name=R2
L=0.62
model=res_high_po_0p35
spiceprefix=X
mult=1
}
C {lab_pin.sym} 1360 -410 1 0 {name=l10_M sig_type=std_logic lab=net5}
C {lab_pin.sym} 1360 -510 3 0 {name=l10_P sig_type=std_logic lab=net6}
C {lab_pin.sym} 1320 -460 2 0 {name=l10_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/res_xhigh_po_0p35.sym} 1600 -460 0 0 {name=R3
L=0.62
model=res_xhigh_po_0p35
spiceprefix=X
mult=1
}
C {lab_pin.sym} 1600 -410 1 0 {name=l11_M sig_type=std_logic lab=net4}
C {lab_pin.sym} 1600 -510 3 0 {name=l11_P sig_type=std_logic lab=net5}
C {lab_pin.sym} 1560 -460 2 0 {name=l11_B sig_type=std_logic lab=VSS}
C {sky130_fd_pr/cap_mim_m3_1.sym} 400 -220 0 0 {name=C1
model=cap_mim_m3_1
W=2
L=2
MF=1
spiceprefix=X
}
C {lab_pin.sym} 400 -270 3 0 {name=l12_c0 sig_type=std_logic lab=net4}
C {lab_pin.sym} 400 -170 1 0 {name=l12_c1 sig_type=std_logic lab=net1}
C {sky130_fd_pr/cap_var_lvt.sym} 640 -220 0 0 {name=C2
model=cap_var_lvt
W=1
L=0.18
VM=1
spiceprefix=X
}
C {lab_pin.sym} 640 -270 3 0 {name=l13_c0 sig_type=std_logic lab=net1}
C {lab_pin.sym} 640 -170 1 0 {name=l13_c1 sig_type=std_logic lab=VDD}
C {lab_pin.sym} 580 -200 2 0 {name=l13_b sig_type=std_logic lab=VSS}
C {sky130_fd_pr/npn_05v5.sym} 880 -220 0 0 {name=Q1
model=npn_05v5_W1p00L1p00
m=1
spiceprefix=X
}
C {lab_pin.sym} 920 -250 0 0 {name=l14_c sig_type=std_logic lab=VDD}
C {lab_pin.sym} 840 -220 2 0 {name=l14_b sig_type=std_logic lab=net2}
C {lab_pin.sym} 920 -190 0 0 {name=l14_e sig_type=std_logic lab=VSS}
C {lab_pin.sym} 920 -220 0 0 {name=l14_s sig_type=std_logic lab=VSS}
C {sky130_fd_pr/nfet_01v8.sym} 1120 -220 0 0 {name=M8
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {lab_pin.sym} 1160 -250 0 0 {name=l15_D sig_type=std_logic lab=net2}
C {lab_pin.sym} 1080 -220 2 0 {name=l15_G sig_type=std_logic lab=VSS}
C {lab_pin.sym} 1160 -190 0 0 {name=l15_S sig_type=std_logic lab=VSS}
C {lab_pin.sym} 1160 -220 0 0 {name=l15_B sig_type=std_logic lab=VSS}
C {iopin.sym} 160 -700 2 0 {name=p1 lab=VDD}
C {iopin.sym} 160 -660 2 0 {name=p2 lab=VSS}
C {iopin.sym} 160 -620 2 0 {name=p3 lab=G}
