# Findings and work-arounds for the ihp-sg13cmos5l pdk
guard ring does not work, to fix: add 'guard_ring_code', line to the __init__.py file in the pycell folder of the pdk
DigiSub is not in this pdk :´( -> tests can only complete with disable tap extraction enabled
No NBULAY so be careful when copy pasting g2 layouts (layer invisible but exists, drc flags it as well as lvs)
