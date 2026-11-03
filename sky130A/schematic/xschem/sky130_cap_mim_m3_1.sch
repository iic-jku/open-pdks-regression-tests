v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -280 400 -300 {lab=C0}
N 400 -220 400 -200 {lab=C1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/cap_mim_m3_1.sym} 400 -250 0 0 {name=C1
model=cap_mim_m3_1
W=2
L=2
MF=1
spiceprefix=X
}
C {iopin.sym} 400 -300 3 0 {name=p1 lab=C0}
C {iopin.sym} 400 -200 1 0 {name=p2 lab=C1}
