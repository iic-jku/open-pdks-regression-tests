v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 440 -380 440 -360 {lab=LA}
N 440 -300 440 -260 {lab=#net1}
N 440 -200 440 -180 {lab=LB}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Simon Dorrer 2026"}
C {sg13g2_pr/lvsres.sym} 440 -360 0 0 {name=R1
w=4e-6
l=2e-6
spiceprefix=R
layer=TopMetal2
model=lvsres
}
C {sg13g2_pr/lvsres.sym} 440 -260 0 0 {name=R2
w=4e-6
l=1.64e-6
spiceprefix=R
layer=TopMetal1
model=lvsres
}
C {iopin.sym} 440 -380 3 0 {name=p1 lab=LA}
C {iopin.sym} 440 -180 1 0 {name=p2 lab=LB}
