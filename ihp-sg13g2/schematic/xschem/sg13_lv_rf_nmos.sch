v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -250 480 -250 {lab=B}
N 380 -220 380 -200 {lab=S}
N 320 -250 340 -250 {lab=G}
N 380 -300 380 -280 {lab=D}
N 480 -250 480 -160 {lab=B}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=D}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 320 -250 2 0 {name=p3 lab=G}
C {iopin.sym} 480 -160 1 0 {name=p4 lab=B}
C {sg13g2_pr/sg13_lv_rf_nmos.sym} 360 -250 0 0 {name=M1
l=0.72u
w=1.0u
ng=1
m=1
rfmode=1
model=sg13_lv_nmos
lvs_model=rfnmos
spiceprefix=X
}
