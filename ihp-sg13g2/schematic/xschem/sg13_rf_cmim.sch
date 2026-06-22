v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -280 420 -250 {lab=C0}
N 420 -190 420 -160 {lab=C1}
N 340 -220 390 -220 {lab=CX}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 420 -280 3 0 {name=p1 lab=C0}
C {iopin.sym} 420 -160 1 0 {name=p2 lab=C1}
C {sg13g2_pr/cap_rfcmim.sym} 420 -220 0 0 {name=C1 
model=cap_rfcmim
lvs_model=rfcmim
w=10.0e-6
l=10.0e-6
wfeed=5.0e-6
spiceprefix=X}
C {iopin.sym} 340 -220 2 0 {name=p3 lab=CX}
