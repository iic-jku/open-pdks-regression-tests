v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -280 400 -260 {lab=C}
N 400 -200 400 -180 {lab=B}
N 400 -120 400 -100 {lab=B}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sg13g2_pr/dantenna.sym} 400 -230 0 0 {name=D1
model=dantenna
l=0.78u
w=0.78u
spiceprefix=X
}
C {iopin.sym} 400 -280 3 0 {name=p1 lab=C}
C {sg13g2_pr/ptap1_ring.sym} 400 -150 2 0 {name=R1
model=ptap1
spiceprefix=X
w=2.82e-6
l=2.82e-6
rw=0.3e-6
lvs_ignore=short
}
C {iopin.sym} 400 -100 1 0 {name=p2 lab=B}
