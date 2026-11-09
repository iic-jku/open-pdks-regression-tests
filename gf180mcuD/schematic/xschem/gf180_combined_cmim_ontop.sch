v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 180 -440 320 -440 {lab=VDD}
N 320 -440 840 -440 {lab=VDD}
N 840 -440 880 -440 {lab=VDD}
N 880 -440 980 -440 {lab=VDD}
N 980 -440 1340 -440 {lab=VDD}
N 180 300 320 300 {lab=VSS}
N 320 300 720 300 {lab=VSS}
N 720 300 840 300 {lab=VSS}
N 840 300 880 300 {lab=VSS}
N 880 300 940 300 {lab=VSS}
N 940 300 980 300 {lab=VSS}
N 980 300 1060 300 {lab=VSS}
N 1060 300 1100 300 {lab=VSS}
N 1100 300 1200 300 {lab=VSS}
N 1200 300 1340 300 {lab=VSS}
N 180 -140 240 -140 {lab=G}
N 240 -340 240 -220 {lab=G}
N 240 -220 240 -140 {lab=G}
N 240 -140 240 -40 {lab=G}
N 240 -40 240 80 {lab=G}
N 240 -340 280 -340 {lab=G}
N 240 -220 280 -220 {lab=G}
N 240 -40 280 -40 {lab=G}
N 240 80 280 80 {lab=G}
N 320 -440 320 -370 {lab=VDD}
N 320 -310 320 -280 {lab=net1}
N 320 -280 320 -250 {lab=net1}
N 320 -280 440 -280 {lab=net1}
N 440 -280 560 -280 {lab=net1}
N 560 -300 560 -280 {lab=net1}
N 320 -190 320 -170 {lab=VSS}
N 320 -90 320 -70 {lab=VDD}
N 320 -10 320 20 {lab=net3}
N 320 20 320 50 {lab=net3}
N 320 20 680 20 {lab=net3}
N 680 -60 680 20 {lab=net3}
N 320 110 320 300 {lab=VSS}
N 440 -220 440 -200 {lab=VSS}
N 560 -360 680 -360 {lab=net4}
N 680 -300 680 -240 {lab=net5}
N 680 -180 680 -120 {lab=net6}
N 700 -330 720 -330 {lab=VSS}
N 700 -210 720 -210 {lab=VSS}
N 700 -90 720 -90 {lab=VSS}
N 720 -330 720 -210 {lab=VSS}
N 720 -210 720 -90 {lab=VSS}
N 720 -90 720 300 {lab=VSS}
N 880 -440 880 -290 {lab=VDD}
N 840 -440 840 -260 {lab=VDD}
N 880 -230 880 -120 {lab=net2}
N 880 -120 880 30 {lab=net2}
N 980 -440 980 -290 {lab=VDD}
N 980 -230 980 -120 {lab=net2}
N 980 -120 980 30 {lab=net2}
N 840 60 840 300 {lab=VSS}
N 880 90 880 300 {lab=VSS}
N 940 60 940 300 {lab=VSS}
N 980 90 980 300 {lab=VSS}
N 1100 -120 1100 30 {lab=net2}
N 1060 60 1060 300 {lab=VSS}
N 1100 90 1100 300 {lab=VSS}
N 1200 -120 1200 30 {lab=net2}
N 1200 90 1200 300 {lab=VSS}
N 880 -120 980 -120 {lab=net2}
N 980 -120 1100 -120 {lab=net2}
N 1100 -120 1200 -120 {lab=net2}
N 1200 -120 1300 -120 {lab=net2}
N 1340 -440 1340 -150 {lab=VDD}
N 1340 -90 1340 300 {lab=VSS}
N 1340 -120 1350 -120 {lab=VSS}
N 1350 -120 1350 -90 {lab=VSS}
N 1340 -90 1350 -90 {lab=VSS}
N 320 -340 330 -340 {lab=VDD}
N 330 -370 330 -340 {lab=VDD}
N 320 -370 330 -370 {lab=VDD}
N 320 -220 330 -220 {lab=VSS}
N 330 -220 330 -190 {lab=VSS}
N 320 -190 330 -190 {lab=VSS}
N 320 -40 330 -40 {lab=VDD}
N 330 -70 330 -40 {lab=VDD}
N 320 -70 330 -70 {lab=VDD}
N 320 80 330 80 {lab=VSS}
N 330 80 330 110 {lab=VSS}
N 320 110 330 110 {lab=VSS}
N 880 -260 890 -260 {lab=VDD}
N 890 -290 890 -260 {lab=VDD}
N 880 -290 890 -290 {lab=VDD}
N 880 60 890 60 {lab=VSS}
N 890 60 890 90 {lab=VSS}
N 880 90 890 90 {lab=VSS}
N 980 60 990 60 {lab=VSS}
N 990 60 990 90 {lab=VSS}
N 980 90 990 90 {lab=VSS}
N 1100 60 1110 60 {lab=VSS}
N 1110 60 1110 90 {lab=VSS}
N 1100 90 1110 90 {lab=VSS}
C {devices/title.sym} 160 460 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/nfet_03v3.sym} 300 -220 0 0 {name=M1
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_03v3
spiceprefix=X
}
C {gf180mcu_fd_pr/pfet_03v3.sym} 300 -340 0 0 {name=M2
L=0.28u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_03v3
spiceprefix=X
}
C {gf180mcu_fd_pr/nfet_06v0.sym} 300 80 0 0 {name=M3
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_06v0
spiceprefix=X
}
C {gf180mcu_fd_pr/pfet_06v0.sym} 300 -40 0 0 {name=M4
L=0.55u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_06v0
spiceprefix=X
}
C {gf180mcu_fd_pr/nfet_05v0.sym} 860 60 0 0 {name=M5
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_05v0
spiceprefix=X
}
C {gf180mcu_fd_pr/pfet_05v0.sym} 860 -260 0 0 {name=M6
L=0.50u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_05v0
spiceprefix=X
}
C {gf180mcu_fd_pr/nfet_06v0_nvt.sym} 960 60 0 0 {name=M7
L=1.80u
W=0.80u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_06v0_nvt
spiceprefix=X
}
C {gf180mcu_fd_pr/diode_nd2ps_03v3.sym} 1200 60 2 0 {name=D1
model=diode_nd2ps_03v3
r_w=0.36u
r_l=0.565u
m=1
}
C {gf180mcu_fd_pr/diode_pd2nw_03v3.sym} 980 -260 2 0 {name=D2
model=diode_pd2nw_03v3
r_w=0.36u
r_l=0.565u
m=1
}
C {gf180mcu_fd_pr/ppolyf_u.sym} 680 -90 2 0 {name=R1
W=0.8u
L=0.8u
model=ppolyf_u
spiceprefix=X
m=1
lvs_format="@name @pinlist @model W=@W L=@L"
}
C {gf180mcu_fd_pr/npolyf_u.sym} 680 -210 2 0 {name=R2
W=0.8u
L=0.8u
model=npolyf_u
spiceprefix=X
m=1
lvs_format="@name @pinlist @model W=@W L=@L"
}
C {gf180mcu_fd_pr/ppolyf_u_1k.sym} 680 -330 2 0 {name=R3
W=1u
L=1u
model=ppolyf_u_1k
spiceprefix=X
m=1
lvs_format="@name @pinlist @model W=@W L=@L"
}
C {gf180mcu_fd_pr/cap_mim_2f0fF.sym} 560 -330 0 0 {name=C1
W=46u
L=46u
model=cap_mim_2f0fF
spiceprefix=X
m=1
lvs_format="@name @pinlist @model W=@W L=@L"
}
C {gf180mcu_fd_pr/cap_nmos_03v3.sym} 440 -250 0 0 {name=C2
W=1u
L=1u
model=cap_nmos_03v3
spiceprefix=X
m=1
lvs_format="@name @pinlist @model W=@W L=@L"
}
C {gf180mcu_fd_pr/npn_00p54x02p00.sym} 1320 -120 0 0 {name=Q1
model=npn_00p54x02p00
spiceprefix=X
m=1
lvs_format="@name @pinlist @model"
}
C {gf180mcu_fd_pr/nfet_03v3.sym} 1080 60 0 0 {name=M8
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_03v3
spiceprefix=X
}
C {iopin.sym} 180 -440 2 0 {name=p1 lab=VDD}
C {iopin.sym} 180 300 2 0 {name=p2 lab=VSS}
C {iopin.sym} 180 -140 2 0 {name=p3 lab=G}
C {lab_pin.sym} 320 -170 3 0 {name=l1 sig_type=std_logic lab=VSS}
C {lab_pin.sym} 320 -90 1 0 {name=l2 sig_type=std_logic lab=VDD}
C {lab_pin.sym} 440 -200 3 0 {name=l3 sig_type=std_logic lab=VSS}
