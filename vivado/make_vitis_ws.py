# make_vitis_ws.py - Part 3 software setup in batch (Vitis Python API):
# platform from an .xsa, the AFDM test app, and a DDR memory test that runs
# entirely from on-chip RAM (so it works even when DDR does not).
# Usage (from vivado/):  vitis -s make_vitis_ws.py <xsa name without .xsa> <workspace dir>
import os
import re
import sys
import vitis

here = os.path.dirname(os.path.abspath(__file__))
xsa_name, ws = sys.argv[1], os.path.abspath(sys.argv[2])
root = os.path.dirname(here)
domain = "standalone_ps7_cortexa9_0"

client = vitis.create_client()
client.set_workspace(path=ws)

plat = client.create_platform_component(
    name="zed_platform", hw_design=os.path.join(here, xsa_name + ".xsa"),
    os="standalone", cpu="ps7_cortexa9_0", domain_name=domain)
plat.build()
xpfm = client.find_platform_in_repos("zed_platform")

# AFDM modulator test (hls/board/main.c).
app = client.create_app_component(name="afdm_test", platform=xpfm, domain=domain)
app.import_files(from_loc=os.path.join(root, "hls", "board"),
                 files=["main.c", "test_vectors.h"], dest_dir_in_cmp="src")
app.build()

# Memory test placed in on-chip RAM (ps7_ram_0): tests DDR without running from it.
mt = client.create_app_component(name="memtest", platform=xpfm, domain=domain,
                                 template="memory_tests")
lscript = os.path.join(ws, "memtest", "src", "lscript.ld")
txt = open(lscript).read()
txt = re.sub(r">\s*ps7_ddr_0", "> ps7_ram_0", txt)
open(lscript, "w").write(txt)
mt.build()

vitis.dispose()
