v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -280 400 -300 {lab=C}
N 400 -220 400 -200 {lab=A}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/diode.sym} 400 -250 0 0 {name=D1
model=diode_pd2nw_05v5_hvt
area=2.025e+11
perim=1.8e+06
spiceprefix=X
}
C {iopin.sym} 400 -300 3 0 {name=p1 lab=C}
C {iopin.sym} 400 -200 1 0 {name=p2 lab=A}
