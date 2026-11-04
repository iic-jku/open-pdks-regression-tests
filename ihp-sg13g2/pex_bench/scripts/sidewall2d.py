#!/usr/bin/env python3
"""2D field solve of the lateral coupling between two parallel wires on the IHP SG13G2 stack.

Finite-volume Laplace solve on a tensor grid graded toward every edge, ground plane at z = 0,
zero-flux far walls. Planar dielectrics, as in kpex's ihp-sg13g2 stack and capiche's
metal_stack_ihp-sg13g2.py: fox 3.95 to 0.40 um, nitride 6.5 to 0.45 um, 4.1 to 16.13 um, air above.
GatPoly and TopMetal2 sit in conformal dielectrics and are not modelled.

  sidewall2d.py <layer> <width> <space>   coupling in aF/um
  sidewall2d.py <layer> fit               capiche's sweep (min width, min space to 20 um in
                                          0.25 um steps) fitted to b / (s + c) by least squares

Needs numpy and scipy. A point takes a few seconds, a fit a few minutes.

SPDX-FileCopyrightText: 2026 Simon Dorrer
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
"""
import sys
import numpy as np
import scipy.optimize
import scipy.sparse as sp
import scipy.sparse.linalg as spla

EPS0 = 8.8541878  # aF/um
LAYERS = [(0.40, 3.95), (0.45, 6.5), (16.13, 4.1), (1e9, 1.0)]  # (z top, k) from the ground up
METALS = {  # z bottom, thickness, min width, min space
    "metal1": (1.04, 0.42, 0.16, 0.18), "metal2": (2.00, 0.49, 0.20, 0.21),
    "metal3": (3.03, 0.49, 0.20, 0.21), "metal4": (4.06, 0.49, 0.20, 0.21),
    "metal5": (5.09, 0.49, 0.20, 0.21), "topmetal1": (6.43, 2.00, 1.64, 1.64),
}


def graded(breaks, hmin, ratio=1.15, hmax=0.5):
    pts = [breaks[0]]
    for a, b in zip(breaks[:-1], breaks[1:]):
        steps, h, x = [], hmin, 0.0
        while x + h < (b - a) / 2:
            x += h
            steps.append(x)
            h = min(h * ratio, hmax)
        pts += [a + v for v in steps] + [b - v for v in steps] + [b]
    return np.unique(np.round(np.array(pts), 9))


def coupling(zb, t, w, s, hmin=0.002, X=45.0, Z=40.0, layers=LAYERS):
    """Return (C12, C11) in aF/um for wires a and b, a at 1 V, b and ground at 0 V."""
    zt = zb + t
    xa, xb = (-s / 2 - w, -s / 2), (s / 2, s / 2 + w)
    x = graded([-X, xa[0], xa[1], xb[0], xb[1], X], hmin)
    z = graded(sorted({0.0, zb, zt, Z} | {zl for zl, _ in layers if zl < Z}), hmin)
    nx, nz = len(x), len(z)
    zc = 0.5 * (z[:-1] + z[1:])
    kc = np.zeros_like(zc)
    for ztop, k in reversed(layers):
        kc[zc < ztop] = k
    K = np.tile(kc, (nx - 1, 1))
    dx, dz = np.diff(x), np.diff(z)
    # conductance of each link: permittivity times face length over link length
    Kz = np.zeros((nx - 1, nz + 1))
    Kz[:, 1:-1] = K
    dzp = np.r_[0, dz, 0]
    gx = (Kz[:, :-1] * dzp[:-1] + Kz[:, 1:] * dzp[1:]) / 2 / dx[:, None]
    Kx = np.zeros((nx + 1, nz - 1))
    Kx[1:-1, :] = K
    dxp = np.r_[0, dx, 0]
    gz = (Kx[:-1, :] * dxp[:-1, None] + Kx[1:, :] * dxp[1:, None]) / 2 / dz[None, :]
    idx = np.arange(nx * nz).reshape(nx, nz)
    r = np.r_[idx[:-1, :].ravel(), idx[:, :-1].ravel()]
    c = np.r_[idx[1:, :].ravel(), idx[:, 1:].ravel()]
    g = np.r_[gx.ravel(), gz.ravel()]
    G = sp.coo_matrix((g, (r, c)), shape=(nx * nz,) * 2).tocsr()
    G = G + G.T
    L = sp.diags(np.asarray(G.sum(axis=1)).ravel()) - G  # (L phi)_n = net flux out of node n
    X2, Z2 = np.meshgrid(x, z, indexing="ij")
    e = 1e-9
    inz = (Z2 >= zb - e) & (Z2 <= zt + e)
    ina = (inz & (X2 >= xa[0] - e) & (X2 <= xa[1] + e)).ravel()
    inb = (inz & (X2 >= xb[0] - e) & (X2 <= xb[1] + e)).ravel()
    fixed = ina | inb | (np.abs(Z2) < e).ravel()
    free = ~fixed
    phi = np.where(ina, 1.0, 0.0)
    phi[free] = spla.spsolve(L[free][:, free].tocsc(), -L[free][:, fixed] @ phi[fixed])
    q = L @ phi * EPS0
    return -q[inb].sum(), q[ina].sum()


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4) or sys.argv[1] not in METALS:
        sys.exit(__doc__.split("\n\n")[2] + "\n\nlayers: " + ", ".join(METALS))
    zb, t, wmin, smin = METALS[sys.argv[1]]
    if sys.argv[2] == "fit":
        seps = np.arange(smin, 20.0, 0.25)
        ys = np.array([coupling(zb, t, wmin, s, hmin=0.004)[0] for s in seps])
        (b, c), _ = scipy.optimize.curve_fit(lambda s, b, c: b / (s + c), seps, ys, p0=[30.0, 0.0])
        print("%s: b = %.3f aF, c = %.3f um" % (sys.argv[1], b, c))
    else:
        print("%.3f aF/um" % coupling(zb, t, float(sys.argv[2]), float(sys.argv[3]))[0])
