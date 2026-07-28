v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -380 420 -360 {lab=S}
N 420 -240 420 -200 {lab=VSS}
N 420 -380 500 -380 {lab=S}
N 500 -380 500 -220 {lab=S}
N 300 -300 420 -300 {lab=VDD}
N 720 -340 720 -300 {lab=D}
N 720 -240 720 -220 {lab=S}
N 640 -270 680 -270 {lab=G}
N 720 -270 730 -270 {lab=S}
N 730 -270 730 -220 {lab=S}
N 720 -220 730 -220 {lab=S}
N 500 -220 720 -220 {lab=S}
N 720 -220 720 -200 {lab=S}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sg13g2_pr/isolbox.sym} 420 -300 0 0 {name=D1
model=isolbox
l=10.0u
w=10.0u
spiceprefix=X
}
C {iopin.sym} 420 -200 1 0 {name=p2 lab=VSS}
C {iopin.sym} 720 -200 1 0 {name=p1 lab=S}
C {iopin.sym} 300 -300 2 0 {name=p3 lab=VDD}
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
C {iopin.sym} 720 -340 3 0 {name=p5 lab=D}
