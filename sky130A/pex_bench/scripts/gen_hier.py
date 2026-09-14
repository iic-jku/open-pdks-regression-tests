# A real transistor with a long, unambiguous wire on its gate, to test whether
# "ext2spice hierarchy on" drops the wire's substrate capacitance.
#
# The wire is on met2, which no cell of sky130_fd_sc_hd uses. Reaching it takes two cuts here,
# not one as in the other PDKs: the standard cell's pins are on the local interconnect li1, and
# met1 is already occupied by the power rails, so the path is li1 -> mcon -> met1 pad -> via ->
# met2. The met1 pad stays well clear of the rails, which run along the top and bottom edges.
import os
import pya

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False

LIB = os.environ.get("STD_CELL_LIBRARY", "sky130_fd_sc_hd")
PDK = os.environ.get("PDKPATH", "/foss/pdks/sky130A")
CELL = LIB + "__inv_1"
PIN = "A"
# This library labels its pins on the li1 label purpose (67/5), draws the pin box on 67/16 and
# the metal itself on 67/20. The label layer is the one to search; the pin box gives the cut
# position, and it is exactly one mcon wide.
LI_LABEL, LI_PIN, LI = (67, 5), (67, 16), (67, 20)
MCON, M1, VIA, M2 = (67, 44), (68, 20), (68, 44), (69, 20)
MCON_CUT, VIA_CUT = 0.17, 0.15
PAD = 0.40          # met1 and met2 landing pad, comfortably larger than either cut

src = pya.Layout()
src.read("%s/libs.ref/%s/gds/%s.gds" % (PDK, LIB, LIB))
cell = src.cell(CELL)
assert cell is not None, "no cell %s in %s" % (CELL, LIB)

pin_pt = None
li = src.find_layer(*LI_LABEL)
assert li is not None, "no li1 label layer %s/%s" % LI_LABEL
for sh in cell.shapes(li).each():
    if sh.is_text() and sh.text.string == PIN:
        pin_pt = sh.dtext.position()
assert pin_pt, "no %s label on li1" % PIN

# The pin box is what the cut has to sit inside; fall back to the drawn li1 shape under the
# label if this library ever stops drawing pin boxes.
pin_box = None
for layer in (LI_PIN, LI):
    li = src.find_layer(*layer)
    if li is None:
        continue
    for sh in cell.shapes(li).each():
        if sh.is_box() and sh.dbox.contains(pin_pt):
            pin_box = sh.dbox
            break
    if pin_box is not None:
        break
assert pin_box is not None, "%s label at %s is not on a drawn li1 box" % (PIN, pin_pt)
print("%s pin at %s, li1 pin box %s" % (PIN, pin_pt, pin_box))

out = pya.Layout()
out.dbu = src.dbu
top = out.create_cell("hier_test")
inv = out.create_cell(CELL)
inv.copy_tree(cell)
top.insert(pya.DCellInstArray(inv.cell_index(), pya.DTrans()))


def square(layer, cx, cy, size):
    top.shapes(out.layer(*layer)).insert(
        pya.DBox(cx - size / 2, cy - size / 2, cx + size / 2, cy + size / 2))


c = pin_box.center()
square(MCON, c.x, c.y, MCON_CUT)
square(M1, c.x, c.y, PAD)
square(VIA, c.x, c.y, VIA_CUT)
square(M2, c.x, c.y, PAD)
# 0.5 x 200 um met2 wire running +x out of the pad
top.shapes(out.layer(*M2)).insert(pya.DBox(c.x, c.y - 0.25, c.x + 200.0, c.y + 0.25))
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
