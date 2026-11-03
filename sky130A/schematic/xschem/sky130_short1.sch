v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -730 440 -730 {lab=VDD}
N 380 -700 360 -700 {lab=VDD}
N 420 -670 440 -670 {lab=VDD}
N 420 -700 440 -700 {lab=VDD}
N 660 -670 680 -670 {lab=VDD}
N 620 -700 600 -700 {lab=VDD}
N 660 -730 680 -730 {lab=VDD}
N 660 -700 680 -700 {lab=VDD}
N 900 -730 920 -730 {lab=VDD}
N 860 -700 840 -700 {lab=VDD}
N 900 -670 920 -670 {lab=VDD}
N 900 -700 920 -700 {lab=VDD}
N 1140 -670 1160 -670 {lab=VDD}
N 1100 -700 1080 -700 {lab=VDD}
N 1140 -730 1160 -730 {lab=VDD}
N 1140 -700 1160 -700 {lab=VDD}
N 160 -700 200 -700 {lab=VDD}
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
C {lab_pin.sym} 440 -730 0 0 {name=l0_D sig_type=std_logic lab=VDD}
C {lab_pin.sym} 360 -700 2 0 {name=l0_G sig_type=std_logic lab=VDD}
C {lab_pin.sym} 440 -670 0 0 {name=l0_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 440 -700 0 0 {name=l0_B sig_type=std_logic lab=VDD}
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
C {lab_pin.sym} 680 -670 0 0 {name=l1_D sig_type=std_logic lab=VDD}
C {lab_pin.sym} 600 -700 2 0 {name=l1_G sig_type=std_logic lab=VDD}
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
C {lab_pin.sym} 920 -730 0 0 {name=l2_D sig_type=std_logic lab=VDD}
C {lab_pin.sym} 840 -700 2 0 {name=l2_G sig_type=std_logic lab=VDD}
C {lab_pin.sym} 920 -670 0 0 {name=l2_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 920 -700 0 0 {name=l2_B sig_type=std_logic lab=VDD}
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
C {lab_pin.sym} 1160 -670 0 0 {name=l3_D sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1080 -700 2 0 {name=l3_G sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1160 -730 0 0 {name=l3_S sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1160 -700 0 0 {name=l3_B sig_type=std_logic lab=VDD}
C {iopin.sym} 160 -700 2 0 {name=p1 lab=VDD}
