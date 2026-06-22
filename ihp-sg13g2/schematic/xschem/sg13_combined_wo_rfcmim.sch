v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 610 -160 630 -160 {lab=G}
N 610 -280 610 -160 {lab=G}
N 610 -280 630 -280 {lab=G}
N 670 -220 670 -190 {lab=#net1}
N 670 -220 850 -220 {lab=#net1}
N 670 -250 670 -220 {lab=#net1}
N 670 -320 670 -310 {lab=VDD}
N 670 -130 670 -120 {lab=VSS}
N 590 -280 610 -280 {lab=G}
N 670 -280 680 -280 {lab=VDD}
N 680 -310 680 -280 {lab=VDD}
N 670 -310 680 -310 {lab=VDD}
N 670 -130 680 -130 {lab=VSS}
N 1090 -70 1100 -70 {lab=VSS}
N 1040 -40 1040 -20 {lab=VSS}
N 1090 -20 1140 -20 {lab=VSS}
N 1140 -40 1140 -20 {lab=VSS}
N 1040 -120 1040 -110 {lab=#net2}
N 1090 -150 1100 -150 {lab=VDD}
N 1140 -120 1140 -110 {lab=#net2}
N 1040 -110 1140 -110 {lab=#net2}
N 1030 -70 1040 -70 {lab=psub}
N 1030 0 1030 20 {lab=psub}
N 1030 0 1150 0 {lab=psub}
N 1030 -70 1030 0 {lab=psub}
N 1150 -70 1150 0 {lab=psub}
N 1140 -70 1150 -70 {lab=psub}
N 1090 -20 1090 100 {lab=VSS}
N 1040 -20 1090 -20 {lab=VSS}
N 1030 100 1090 100 {lab=VSS}
N 1030 80 1030 100 {lab=VSS}
N 1030 -150 1040 -150 {lab=#net3}
N 1030 -240 1030 -220 {lab=#net3}
N 1030 -320 1030 -300 {lab=VDD}
N 1030 -320 1090 -320 {lab=VDD}
N 1040 -200 1040 -180 {lab=VDD}
N 1090 -200 1140 -200 {lab=VDD}
N 1140 -200 1140 -180 {lab=VDD}
N 1090 -320 1090 -200 {lab=VDD}
N 1040 -200 1090 -200 {lab=VDD}
N 1030 -220 1150 -220 {lab=#net3}
N 1030 -220 1030 -150 {lab=#net3}
N 1150 -220 1150 -150 {lab=#net3}
N 1140 -150 1150 -150 {lab=#net3}
N 1040 -110 1040 -100 {lab=#net2}
N 1140 -110 1140 -100 {lab=#net2}
N 1030 100 1030 110 {lab=VSS}
N 1030 -330 1030 -320 {lab=VDD}
N 670 100 670 120 {lab=#net4}
N 610 50 630 50 {lab=G}
N 610 50 610 150 {lab=G}
N 610 150 630 150 {lab=G}
N 670 50 680 50 {lab=VDD}
N 680 10 680 50 {lab=VDD}
N 670 10 680 10 {lab=VDD}
N 670 10 670 20 {lab=VDD}
N 670 0 670 10 {lab=VDD}
N 670 190 670 200 {lab=VSS}
N 670 190 680 190 {lab=VSS}
N 670 180 670 190 {lab=VSS}
N 670 100 850 100 {lab=#net4}
N 670 80 670 100 {lab=#net4}
N 610 -160 610 50 {lab=G}
N 850 -220 850 -210 {lab=#net1}
N 850 -150 850 -140 {lab=#net5}
N 850 -80 850 -60 {lab=#net6}
N 850 80 850 100 {lab=#net4}
N 850 -0 850 20 {lab=#net7}
N 1140 -110 1320 -110 {lab=#net2}
N 1320 -120 1320 -110 {lab=#net2
}
N 1320 -110 1320 -100 {lab=#net2
}
N 1320 -40 1320 -0 {lab=psub}
N 850 100 850 120 {lab=#net4}
N 1090 -70 1090 -20 {lab=VSS}
N 1080 -70 1090 -70 {lab=VSS}
N 1090 -200 1090 -150 {lab=VDD}
N 1080 -150 1090 -150 {lab=VDD}
N 1150 0 1320 -0 {lab=psub}
N 1150 -220 1320 -220 {lab=#net3}
N 1320 -220 1320 -180 {lab=#net3}
N 860 160 860 190 {lab=VSS
}
N 850 190 850 200 {lab=VSS
}
N 680 -160 680 -130 {lab=VSS}
N 670 -160 680 -160 {lab=VSS}
N 680 150 680 190 {lab=VSS}
N 670 150 680 150 {lab=VSS}
N 850 190 860 190 {lab=VSS}
N 850 180 850 190 {lab=VSS
}
C {sg13g2_pr/cap_cmim.sym} 850 -180 2 0 {name=C1
model=cap_cmim
w=20.0e-6
l=20.0e-6
m=1
spiceprefix=X}
C {sg13g2_pr/sg13_lv_rf_nmos.sym} 650 -160 0 0 {name=M1
l=0.72u
w=1.0u
ng=1
m=1
rfmode=1
model=sg13_lv_nmos
lvs_model=rfnmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_rf_pmos.sym} 650 -280 0 0 {name=M2
l=0.72u
w=1.0u
ng=1
m=1
rfmode=1
model=sg13_lv_pmos
lvs_model=rfpmos
spiceprefix=X
}
C {iopin.sym} 670 -320 3 0 {name=p2 lab=VDD}
C {iopin.sym} 670 -120 1 0 {name=p3 lab=VSS}
C {iopin.sym} 590 -280 2 0 {name=p4 lab=G}
C {sg13g2_pr/dantenna.sym} 1320 -70 0 0 {name=D1
model=dantenna
l=0.78u
w=0.78u
spiceprefix=X
}
C {sg13g2_pr/dpantenna.sym} 1320 -150 0 0 {name=D2
model=dpantenna
l=0.78u
w=0.78u
spiceprefix=X
}
C {sg13g2_pr/schottky_nbl1.sym} 850 150 0 0 {name=D3
model=schottky_nbl1
Nx=1
Ny=1
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 1120 -70 0 0 {name=M3
l=0.45u
w=0.15u
ng=1
m=1
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 1120 -150 0 0 {name=M4
l=0.45u
w=0.15u
ng=1
m=1
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_hv_pmos.sym} 1060 -150 0 1 {name=M5
l=0.45u
w=0.3u
ng=1
m=1
model=sg13_hv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_hv_nmos.sym} 1060 -70 0 1 {name=M6
l=0.45u
w=0.3u
ng=1
m=1
model=sg13_hv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_hv_rf_nmos.sym} 650 150 0 0 {name=M7
l=0.72u
w=1.0u
ng=1
m=1
rfmode=1
model=sg13_hv_nmos
lvs_model=rfnmoshv
spiceprefix=X
}
C {sg13g2_pr/sg13_hv_rf_pmos.sym} 650 50 0 0 {name=M8
l=0.72u
w=1.0u
ng=1
m=1
rfmode=1
model=sg13_hv_pmos
lvs_model=rfpmoshv
spiceprefix=X
}
C {sg13g2_pr/rsil.sym} 850 50 0 0 {name=R1
w=0.5e-6
l=0.5e-6
model=rsil
body="tcleval([expr \\\{$lvs_ignore ? \\\{VSS\\\} : \\\{psub\\\}\\\}])"
spiceprefix=X
m=1
value="expr_eng(  ( 9.0e-6 / @w + 7.0 * ( @l ) / ( @w + 1.0e-8 ) ) / @m  )"
}
C {sg13g2_pr/rppd.sym} 850 -30 0 0 {name=R2
w=0.5e-6
l=0.5e-6
model=rppd
body="tcleval([expr \\\{$lvs_ignore ? \\\{VSS\\\} : \\\{psub\\\}\\\}])"
spiceprefix=X
b=0
m=1
value="expr_eng(  ( 70.0e-6 / @w + 260.0 * ( (@b + 1)* @l + ( 1.081*( @w + 6.0e-9 ) + 0.18e-6 )*@b ) / ( @w + 6.0e-9 ) ) / @m  )"
}
C {sg13g2_pr/rhigh.sym} 850 -110 0 0 {name=R3
w=0.5e-6
l=0.96e-6
model=rhigh
body="tcleval([expr \\\{$lvs_ignore ? \\\{VSS\\\} : \\\{psub\\\}\\\}])"
spiceprefix=X
b=0
m=1
value="expr_eng(  ( 1.6e-4 / @w + 1360.0 * ( (@b + 1)* @l + ( 1.081*( @w - 0.04e-6 ) + 0.18e-6 )*@b ) / ( @w - 0.04e-6 ) ) / @m  )"
}
C {sg13g2_pr/ptap1_ring.sym} 1030 50 2 0 {name=R4
model=ptap1
spiceprefix=X
w=3e-6
l=4e-6
rw=0.3e-6
lvs_ignore=short}
C {sg13g2_pr/ntap1_ring.sym} 1030 -270 0 1 {name=R5
model=ntap1
spiceprefix=X
w=4.5e-6
l=4e-6
rw=0.3e-6
lvs_ignore=short}
C {lab_pin.sym} 670 0 1 0 {name=p1 sig_type=std_logic lab=VDD}
C {lab_pin.sym} 670 200 3 0 {name=p7 sig_type=std_logic lab=VSS}
C {lab_pin.sym} 1030 -330 1 0 {name=p6 sig_type=std_logic lab=VDD}
C {lab_pin.sym} 1030 110 3 0 {name=p5 sig_type=std_logic lab=VSS}
C {lab_pin.sym} 850 200 3 0 {name=p11 sig_type=std_logic lab=VSS
}
C {lab_wire.sym} 1140 0 0 0 {name=p9 sig_type=std_logic lab="tcleval([expr \\\{$lvs_ignore ? \\\{VSS\\\} : \\\{psub\\\}\\\}])"}
