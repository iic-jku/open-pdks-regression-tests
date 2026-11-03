# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Check that a full-RC PEX netlist connects devices and ports like the C-coupled
# netlist of the same cell. Run by the magic-pex and klayout-pex targets of common.mk for
# EXT_MODE=3, after check_pex_ports.py.
#
# check_pex_ports.py only asks whether every port reaches some element. A full-RC netlist can
# pass that and still be wrong: two ports joined through resistors, or a device terminal that
# no longer reaches its port while other elements keep the port busy. Both show up against
# the C-coupled netlist (EXT_MODE=2), which has the same devices without the resistance
# network: in the full-RC netlist every node is merged with the nodes it reaches through
# resistors, and each device terminal is then mapped to the ports of its net.
import argparse
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_pex_ports import Union, nodes_of, subcircuits  # noqa: E402  same netlist reader

# elements that carry the circuit; r is the resistance network, c/l/v/i/k are not devices
DEVICE = ("x", "m", "q", "d", "j")


def top_block(path):
    """The extracted subcircuit: the one named <cell>_pex, otherwise the last one."""
    blocks = subcircuits(path)
    if not blocks:
        return None
    named = [b for b in blocks if b[0].endswith("_pex")]
    return (named or blocks)[-1]


def connections(block, keep):
    """Merge the nodes joined through resistors. Return (net of a node, ports of each net, Counter of
    devices with the ports in `keep` that each terminal reaches)."""
    _, ports, elements = block
    net = Union()
    for tokens in elements:
        nodes = nodes_of(tokens)
        if tokens[0][0].lower() == "r" and len(nodes) == 2:
            net.union(nodes[0], nodes[1])
    ports_of = {}
    for port in ports:
        ports_of.setdefault(net.find(port), set()).add(port)
    devices = Counter()
    for tokens in elements:
        if tokens[0][0].lower() not in DEVICE:
            continue
        nodes = nodes_of(tokens)
        # the model follows the nodes, for subcircuit calls and devices alike
        model = tokens[len(nodes) + 1] if len(tokens) > len(nodes) + 1 else "?"
        where = tuple("+".join(sorted(ports_of.get(net.find(n), set()) & keep)) or "-" for n in nodes)
        devices[(model, where)] += 1
    return net, ports_of, devices


def fmt(device):
    model, where = device
    return f"{model} ({', '.join(where)})"


def compare(rc_path, cc_path):
    """Return the list of differences between the full-RC and the C-coupled netlist.

    The C-coupled netlist writes one port per net: a net with two pins keeps one name. The
    full-RC netlist keeps both and puts the resistance between them. So the ports of the
    C-coupled netlist are the reference: a port only the full-RC netlist has must reach exactly
    one of them through resistors, and two of them joined through resistors are a short."""
    rc, cc = top_block(rc_path), top_block(cc_path)
    if rc is None or cc is None:
        return [f"{rc_path if rc is None else cc_path}: no subcircuit found"]
    problems = []
    keep = set(cc[1])
    for port in sorted(keep - set(rc[1])):
        problems.append(f"{rc_path}: port {port} of {cc_path} is missing.")
    rc_net, rc_ports, rc_devices = connections(rc, keep)
    cc_net, _, cc_devices = connections(cc, keep)
    for group in sorted(tuple(sorted(g)) for g in rc_ports.values()):
        known = [p for p in group if p in keep]
        if len({cc_net.find(p) for p in known}) > 1:
            problems.append(f"{rc_path}: ports {', '.join(known)} are one net through resistors, "
                            f"but separate nets in {cc_path}.")
        for port in group:
            if port not in keep and not known:
                problems.append(f"{rc_path}: port {port} reaches none of the ports of {cc_path} "
                                f"through resistors.")
    lost, new = cc_devices - rc_devices, rc_devices - cc_devices
    for device, n in sorted(lost.items()):
        problems.append(f"{cc_path}: {n} x {fmt(device)} has no counterpart in {rc_path}.")
    for device, n in sorted(new.items()):
        problems.append(f"{rc_path}: {n} x {fmt(device)} has no counterpart in {cc_path}.")
    return problems


def main():
    parser = argparse.ArgumentParser(
        description="Check that a full-RC PEX netlist connects devices and ports like the "
                    "C-coupled netlist of the same cell. Ports are written as they are, "
                    "'a+b' for a net that reaches several ports, '-' for a net that reaches none."
    )
    parser.add_argument("full_rc", help="full-RC netlist (EXT_MODE=3)")
    parser.add_argument("c_coupled", help="C-coupled netlist of the same cell (EXT_MODE=2)")
    parser.add_argument("--layout", help="layout the netlists were extracted from: a C-coupled "
                        "netlist older than it is not compared")
    args = parser.parse_args()

    print(f"[INFO] Comparing the full-RC netlist {args.full_rc} with {args.c_coupled} ...")
    if not os.path.isfile(args.c_coupled):
        print(f"[INFO] No C-coupled netlist {args.c_coupled}, connections not compared. "
              f"Run EXT_MODE=2 first to compare them.")
        return 0
    if args.layout and os.path.getmtime(args.c_coupled) < os.path.getmtime(args.layout):
        print(f"[WARNING] {args.c_coupled} is older than {args.layout}, connections not "
              f"compared. Run EXT_MODE=2 again to compare them.")
        return 0

    problems = compare(args.full_rc, args.c_coupled)
    for problem in problems:
        print(f"[ERROR] {problem}", file=sys.stderr)
    if problems:
        print(f"[ERROR] {len(problems)} difference(s): the full-RC netlist does not connect "
              f"devices and ports like the C-coupled one.", file=sys.stderr)
        return 1
    print("[INFO] Full-RC and C-coupled netlists connect devices and ports alike.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
