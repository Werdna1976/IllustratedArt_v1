"""Print the mean RGB of a region of a PNG (cheap visual checks without viewing images).
usage: python tools/art/probe_px.py <png> <x0> <y0> <x1> <y1>"""
import sys
import numpy as np
from PIL import Image

a = np.asarray(Image.open(sys.argv[1]).convert("RGB"))
x0, y0, x1, y1 = map(int, sys.argv[2:6])
print("mean rgb", a[y0:y1, x0:x1].reshape(-1, 3).mean(axis=0).round(1))
