import json, os, sys, tempfile, unittest
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import pack_parts


def part(d, name, size, rgba=(200, 50, 50, 255)):
    Image.new("RGBA", size, rgba).save(os.path.join(d, name + ".png"))


class PackPartsTest(unittest.TestCase):
    def test_packs_parts_with_rects_pivots_and_emit(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = os.path.join(d, "parts"), os.path.join(d, "char")
            os.makedirs(src)
            part(src, "thigh_near", (60, 170))
            part(src, "katana", (440, 32))
            part(src, "katana_emit", (440, 32), (0, 255, 0, 255))
            json.dump({"assets": {"thigh_near.png": {"recommended_joint_center": [30, 25], "distal_joint_center": [30, 145]}}},
                      open(os.path.join(src, "manifest.json"), "w"))
            pack_parts.main([src, out])
            rects = json.load(open(os.path.join(out, "parts.json")))
            self.assertEqual(rects["katana"][2:], [440, 32])
            pivots = json.load(open(os.path.join(out, "pivots.json")))
            self.assertEqual(pivots["thigh_near"], {"pivot": [30, 25], "distal": [30, 145]})
            self.assertEqual(pivots["katana"]["pivot"], [105, 16])  # brief default
            sheet = np.asarray(Image.open(os.path.join(out, "parts.png")))
            emit = np.asarray(Image.open(os.path.join(out, "parts_emit.png")))
            self.assertEqual(sheet.shape[:2], (2048, 2048))
            kx, ky, kw, kh = rects["katana"]
            self.assertEqual(tuple(emit[ky + 5, kx + 5, :3]), (0, 255, 0))
            tx, ty = rects["thigh_near"][:2]
            self.assertEqual(int(emit[ty + 5, tx + 5, :3].max()), 0)  # no mask -> no glow
            self.assertTrue(os.path.exists(os.path.join(out, "parts_n.png")))

    def test_missing_and_wrong_size_parts_are_reported(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = os.path.join(d, "parts"), os.path.join(d, "char")
            os.makedirs(src)
            part(src, "torso", (100, 200))  # brief says 110 x 230
            warnings = pack_parts.main([src, out])
            self.assertGreaterEqual(warnings, 22)  # 22 missing + 1 wrong size
            self.assertIn("torso", json.load(open(os.path.join(out, "parts.json"))))


if __name__ == "__main__":
    unittest.main()
