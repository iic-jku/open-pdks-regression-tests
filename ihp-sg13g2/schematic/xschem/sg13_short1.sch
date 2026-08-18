v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N -20 -40 190 -40 {lab=VDD}
N 150 20 190 20 {lab=VDD}
N -270 -10 -230 20 {lab=VDD}
N -230 -10 -230 20 {lab=VDD}
N -90 -10 -90 20 {lab=VDD}
N -130 20 -90 20 {lab=VDD}
N 50 -10 50 20 {lab=VDD}
N 10 20 50 20 {lab=VDD}
N 190 -10 190 20 {lab=VDD}
N 150 -10 150 20 {lab=VDD}
N 50 20 150 20 {lab=VDD}
N 10 -10 10 20 {lab=VDD}
N -20 20 10 20 {lab=VDD}
N -130 -10 -130 20 {lab=VDD}
N -230 20 -130 20 {lab=VDD}
N -20 -40 -20 20 {lab=VDD}
N -230 -40 -20 -40 {lab=VDD}
N -90 20 -20 20 {lab=VDD}
C {sg13g2_pr/sg13_hv_nmos.sym} -110 -10 0 0 {name=M1
l=0.45u
w=0.3u
 ng=1
 m=1
  mm_ok=1
 model=sg13_hv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_hv_pmos.sym} 170 -10 0 0 {name=M2
l=0.4u
w=0.3u
 ng=1
 m=1
  mm_ok=1
 model=sg13_hv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} -250 -10 0 0 {name=M3
l=0.13u
w=0.15u
ng=1
m=1
mm_ok=1
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 30 -10 0 0 {name=M4
l=0.13u
w=0.15u
ng=1
m=1
mm_ok=1
model=sg13_lv_pmos
spiceprefix=X
}
C {iopin.sym} -270 -10 2 0 {name=p1 lab=VDD}
