v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 360 -700 380 -700 {lab=VDD}
N 420 -700 440 -700 {lab=VDD}
N 600 -700 620 -700 {lab=VDD}
N 660 -700 680 -700 {lab=VDD}
N 840 -700 860 -700 {lab=VDD}
N 900 -700 920 -700 {lab=VDD}
N 1080 -700 1100 -700 {lab=VDD}
N 1140 -700 1160 -700 {lab=VDD}
N 160 -700 200 -700 {lab=VDD}
N 420 -670 420 -640 {lab=VDD}
N 280 -640 420 -640 {lab=VDD}
N 280 -700 280 -640 {lab=VDD}
N 420 -640 660 -640 {lab=VDD}
N 660 -670 660 -640 {lab=VDD}
N 660 -640 900 -640 {lab=VDD}
N 900 -670 900 -640 {lab=VDD}
N 900 -640 1140 -640 {lab=VDD}
N 1140 -670 1140 -640 {lab=VDD}
N 1160 -700 1180 -700 {lab=VDD}
N 1180 -700 1180 -640 {lab=VDD}
N 1140 -640 1180 -640 {lab=VDD}
N 280 -760 280 -700 {lab=VDD}
N 280 -760 1140 -760 {lab=VDD}
N 1140 -760 1140 -730 {lab=VDD}
N 900 -760 900 -730 {lab=VDD}
N 660 -760 660 -730 {lab=VDD}
N 420 -760 420 -730 {lab=VDD}
N 360 -760 360 -700 {lab=VDD}
N 200 -700 280 -700 {lab=VDD}
N 440 -700 460 -700 {lab=VDD}
N 460 -700 460 -640 {lab=VDD}
N 680 -700 700 -700 {lab=VDD}
N 700 -700 700 -640 {lab=VDD}
N 920 -700 940 -700 {lab=VDD}
N 940 -700 940 -640 {lab=VDD}
N 1080 -750 1080 -700 {lab=VDD}
N 1080 -760 1080 -750 {lab=VDD}
N 840 -760 840 -700 {lab=VDD}
N 600 -760 600 -700 {lab=VDD}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/nfet_03v3.sym} 400 -700 0 0 {name=M1
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_03v3
spiceprefix=X
}
C {gf180mcu_fd_pr/pfet_03v3.sym} 640 -700 0 0 {name=M2
L=0.28u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_03v3
spiceprefix=X
}
C {gf180mcu_fd_pr/nfet_06v0.sym} 880 -700 0 0 {name=M3
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_06v0
spiceprefix=X
}
C {gf180mcu_fd_pr/pfet_06v0.sym} 1120 -700 0 0 {name=M4
L=0.55u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_06v0
spiceprefix=X
}
C {iopin.sym} 160 -700 2 0 {name=p1 lab=VDD}
