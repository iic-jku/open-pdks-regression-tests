v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 300 -380 300 -360 {lab=P1}
N 300 -300 300 -280 {lab=P2}
N 560 -460 560 -440 {lab=S1}
N 560 -380 560 -340 {lab=CT}
N 560 -340 620 -340 {lab=CT}
N 560 -280 560 -260 {lab=S2}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Simon Dorrer 2026"}
C {sg13cmos5l_pr/lvsres.sym} 300 -360 0 0 {name=R1
w=4e-6
l=1.64e-6
spiceprefix=R
layer=TopMetal1
model=lvsres
}
C {sg13cmos5l_pr/lvsres.sym} 560 -440 0 0 {name=R2
w=4e-6
l=1e-6
spiceprefix=R
layer=Metal4
model=lvsres
}
C {sg13cmos5l_pr/lvsres.sym} 560 -340 0 0 {name=R3
w=4e-6
l=1e-6
spiceprefix=R
layer=Metal4
model=lvsres
}
C {iopin.sym} 300 -380 3 0 {name=p1 lab=P1}
C {iopin.sym} 300 -280 1 0 {name=p2 lab=P2}
C {iopin.sym} 560 -460 3 0 {name=p3 lab=S1}
C {iopin.sym} 560 -260 1 0 {name=p4 lab=S2}
C {iopin.sym} 620 -340 0 0 {name=p5 lab=CT}
