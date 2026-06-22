v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -200 400 -180 {lab=A}
N 400 -360 400 -340 {lab=B}
N 400 -280 400 -260 {lab=#net1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 400 -180 1 0 {name=p1 lab=A}
C {iopin.sym} 400 -360 3 0 {name=p2 lab=B}
C {sg13g2_pr/dpantenna.sym} 400 -230 0 0 {name=D1
model=dpantenna
l=0.78u
w=0.78u
spiceprefix=X
}
C {sg13g2_pr/ntap1_ring.sym} 400 -310 0 0 {name=R1
model=ntap1
spiceprefix=X
w=3.14e-6
l=3.14e-6
rw=0.3e-6
lvs_ignore=short
}
