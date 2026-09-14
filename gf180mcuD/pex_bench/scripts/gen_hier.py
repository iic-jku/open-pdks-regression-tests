# A real transistor with a long, unambiguous wire on its gate, to test whether
# "ext2spice hierarchy on" drops the wire's substrate capacitance.
# The wire is on Metal2 (unused inside the standard cell), reached by one Via1 on the input pin.
import os
import pya

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False

# This PDK ships one GDS per library rather than one per cell, and the cell names carry a
# double underscore. The inverter's input is called I here, not A as in the IHP libraries.
LIB = os.environ.get("STD_CELL_LIBRARY", "gf180mcu_fd_sc_mcu7t5v0")
PDK = os.environ.get("PDKPATH", "/foss/pdks/gf180mcuD")
CELL = LIB + "__inv_1"
PIN = "I"
M1, M1_PIN, M2, VIA1 = (34, 0), (34, 10), (36, 0), (35, 0)
CUT = 0.26          # every via in this PDK is a fixed 0.26 um cut, rule V1.1

src = pya.Layout()
src.read("%s/libs.ref/%s/gds/%s.gds" % (PDK, LIB, LIB))
cell = src.cell(CELL)
assert cell is not None, "no cell %s in %s" % (CELL, LIB)

# The labels sit on the Metal1 pin datatype, but this library draws no pin boxes there, so the
# landing metal has to come from the drawn Metal1 shape that the label falls inside.
pin_pt = None
li = src.find_layer(*M1_PIN)
assert li is not None, "no Metal1 pin layer %s/%s" % M1_PIN
for sh in cell.shapes(li).each():
    if sh.is_text() and sh.text.string == PIN:
        pin_pt = sh.dtext.position()
assert pin_pt, "no %s label on Metal1" % PIN

pin_box = None
li = src.find_layer(*M1)
for sh in cell.shapes(li).each():
    if sh.is_text():
        continue
    if sh.is_box():
        if sh.dbox.contains(pin_pt):
            pin_box = sh.dbox
            break
    elif sh.dpolygon.inside(pin_pt):
        # A polygon's bounding box would be much larger than the metal, and the Metal2 pad
        # below is drawn on it, so refuse rather than guess. This library draws pin metal as a
        # box; a library that does not needs this generator looked at, not silently accepted.
        raise AssertionError("%s label at %s sits on a polygon, not a box" % (PIN, pin_pt))
assert pin_box is not None, "%s label at %s is not on drawn Metal1" % (PIN, pin_pt)
print("%s pin at %s, landing metal %s" % (PIN, pin_pt, pin_box))

out = pya.Layout()
out.dbu = src.dbu
top = out.create_cell("hier_test")
inv = out.create_cell(CELL)
inv.copy_tree(cell)
top.insert(pya.DCellInstArray(inv.cell_index(), pya.DTrans()))

# One cut in the middle of the landing metal, in x centred on it and in y on the label, so it
# stays inside a box that is only a little wider than the cut itself.
cx = (pin_box.left + pin_box.right) / 2.0
cy = pin_pt.y
assert pin_box.contains(pya.DPoint(cx - CUT / 2, cy - CUT / 2)), "cut leaves the landing metal"
assert pin_box.contains(pya.DPoint(cx + CUT / 2, cy + CUT / 2)), "cut leaves the landing metal"
top.shapes(out.layer(*VIA1)).insert(
    pya.DBox(cx - CUT / 2, cy - CUT / 2, cx + CUT / 2, cy + CUT / 2))
# Metal2 pad over the whole landing metal, then a 0.5 x 200 um Metal2 wire running +x
top.shapes(out.layer(*M2)).insert(pin_box)
top.shapes(out.layer(*M2)).insert(pya.DBox(cx, cy - 0.25, cx + 200.0, cy + 0.25))
LAY = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")
out.write(os.path.join(LAY, "hier_test.gds"), GDS_OPTS)
print("wrote layout/hier_test.gds")

# The bare standard cell as well, as the device-bearing reference next to hier_test. In the
# sg13g2 bench this layout is committed without a generator, so "make layouts" never
# reproduces it and "make layouts-check" cannot notice: it diffs a copy of layout/ against the
# regenerated one, and a file nothing rewrites matches itself. Writing it here closes that.
bare = pya.Layout()
bare.dbu = src.dbu
bare_top = bare.create_cell(CELL)
bare_top.copy_tree(cell)
bare.write(os.path.join(LAY, CELL + ".gds"), GDS_OPTS)
print("wrote layout/%s.gds" % CELL)
