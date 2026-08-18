v {xschem version=3.4.8RC file_version=1.3
* Copyright 2022 GlobalFoundries PDK Authors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.

}
G {}
K {}
V {}
S {}
F {}
E {}
P 4 1 40 -350 {}
N 50 -410 90 -410 {
lab=G}
N 130 -490 130 -440 {
lab=S}
N 130 -410 230 -410 {
lab=B}
N 130 -380 130 -310 {
lab=D}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz"}
C {iopin.sym} 50 -410 2 0 {name=p2 lab=G}
C {iopin.sym} 130 -310 1 0 {name=p3 lab=D}
C {iopin.sym} 130 -490 3 0 {name=p4 lab=S}
C {iopin.sym} 230 -410 0 0 {name=p1 lab=B}
C {gf180mcu_fd_pr/pfet_06v0.sym} 110 -410 0 0 {name=M1
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
