v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -220 380 -200 {lab=A}
N 380 -300 380 -280 {lab=C}
N 390 -240 440 -240 {lab=B}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=C}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=A}
C {iopin.sym} 440 -240 0 0 {name=p4 lab=B}
C {sg13g2_pr/schottky_nbl1.sym} 380 -250 0 0 {name=D1
model=schottky_nbl1
Nx=1
Ny=1
spiceprefix=X
}
