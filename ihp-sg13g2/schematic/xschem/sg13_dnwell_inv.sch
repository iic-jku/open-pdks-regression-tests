v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -380 420 -360 {lab=#net1}
N 480 -380 500 -380 {lab=#net1}
N 500 -300 500 -220 {lab=S}
N 300 -300 420 -300 {lab=VDD}
N 720 -340 720 -300 {lab=#net2}
N 660 -370 680 -370 {lab=G}
N 660 -370 660 -270 {lab=G}
N 660 -270 680 -270 {lab=G}
N 720 -240 720 -220 {lab=S}
N 640 -270 660 -270 {lab=G}
N 720 -420 720 -400 {lab=D}
N 720 -370 800 -370 {lab=#net3}
N 500 -220 720 -220 {lab=S}
N 720 -220 720 -200 {lab=S}
N 860 -370 880 -370 {lab=VDD}
N 420 -160 420 -140 {lab=VSS}
N 420 -240 420 -220 {lab=#net4}
N 500 -380 500 -360 {lab=#net1}
N 480 -380 480 -160 {lab=#net1}
N 420 -380 480 -380 {lab=#net1}
N 480 -160 820 -160 {lab=#net1}
N 820 -270 820 -160 {lab=#net1}
N 720 -270 820 -270 {lab=#net1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sg13g2_pr/isolbox.sym} 420 -300 0 0 {name=D1
model=isolbox
l=10.0u
w=10.0u
spiceprefix=X
}
C {iopin.sym} 420 -140 1 0 {name=p2 lab=VSS}
C {iopin.sym} 720 -200 1 0 {name=p1 lab=S}
C {iopin.sym} 300 -300 2 0 {name=p3 lab=VDD}
C {sg13g2_pr/sg13_lv_pmos.sym} 700 -370 0 0 {name=M1
l=0.13u
w=0.15u
ng=1
m=1
mm_ok=1
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 700 -270 0 0 {name=M2
l=0.13u
w=0.15u
ng=1
m=1
mm_ok=1
model=sg13_lv_nmos
spiceprefix=X
}
C {iopin.sym} 640 -270 2 0 {name=p4 lab=G}
C {iopin.sym} 720 -420 3 0 {name=p5 lab=D}
C {lab_pin.sym} 880 -370 2 0 {name=p6 sig_type=std_logic lab=VDD}
C {sg13g2_pr/ptap1.sym} 420 -190 2 0 {name=R1
model=ptap1
spiceprefix=X
w=0.78e-6
l=0.78e-6
lvs_ignore=short
}
C {sg13g2_pr/ptap1.sym} 500 -330 2 1 {name=R2
model=ptap1
spiceprefix=X
w=0.78e-6
l=0.78e-6
lvs_ignore=short
}
C {sg13g2_pr/ntap1.sym} 830 -370 1 0 {name=R3
model=ntap1
spiceprefix=X
w=0.78e-6
l=0.78e-6
lvs_ignore=short
}
