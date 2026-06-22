v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 440 -260 440 -240 {lab=R0}
N 440 -180 440 -160 {lab=R1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 440 -260 3 0 {name=p1 lab=R0}
C {iopin.sym} 440 -160 1 0 {name=p2 lab=R1}
C {sg13g2_pr/rppd.sym} 440 -210 0 0 {name=R1
w=0.5e-6
l=0.5e-6
model=rppd
body=sub!
spiceprefix=X
b=0
m=1
value="expr_eng(  ( 70.0e-6 / @w + 260.0 * ( (@b + 1)* @l + ( 1.081*( @w + 6.0e-9 ) + 0.18e-6 )*@b ) / ( @w + 6.0e-9 ) ) / @m  )"
}
