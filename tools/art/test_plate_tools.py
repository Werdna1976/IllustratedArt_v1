import json, os, sys, tempfile, unittest
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import compose_plate, loop_seam, stitch


def solid(w, h, rgba):
    return Image.new("RGBA", (w, h), rgba)


def save(d, name, img):
    p = os.path.join(d, name); img.save(p); return p


class StitchTest(unittest.TestCase):
    def test_panels_join_with_overlap_and_scale_to_target(self):
        with tempfile.TemporaryDirectory() as d:
            a = save(d, "a.png", solid(100, 50, (255, 0, 0, 255)))
            b = save(d, "b.png", solid(100, 50, (0, 0, 255, 255)))
            out = os.path.join(d, "out.png")
            stitch.main([a, b, "--overlap", "20", "--size", "360x100", "-o", out])
            img = Image.open(out)
            self.assertEqual(img.size, (360, 100))
            px = np.asarray(img)
            self.assertEqual(tuple(px[50, 5, :3]), (255, 0, 0))     # left panel
            self.assertEqual(tuple(px[50, 354, :3]), (0, 0, 255))   # right panel
            mid = px[50, 180, :3]                                    # feathered seam
            self.assertTrue(0 < mid[0] < 255 and 0 < mid[2] < 255, mid)

    def test_panels_of_different_heights_are_matched(self):
        with tempfile.TemporaryDirectory() as d:
            a = save(d, "a.png", solid(100, 50, (255, 0, 0, 255)))
            b = save(d, "b.png", solid(200, 100, (0, 0, 255, 255)))  # 2x resolution
            out = os.path.join(d, "out.png")
            stitch.main([a, b, "--overlap", "10", "-o", out])
            self.assertEqual(Image.open(out).size, (190, 50))

    def test_size_from_sizes_json_layer(self):
        with tempfile.TemporaryDirectory() as d:
            json.dump({"far": [64, 32]}, open(os.path.join(d, "sizes.json"), "w"))
            a = save(d, "a.png", solid(40, 20, (9, 9, 9, 255)))
            out = os.path.join(d, "far.png")
            stitch.main([a, "--layer", "far", "-o", out])
            self.assertEqual(Image.open(out).size, (64, 32))


class ComposeTest(unittest.TestCase):
    def test_tiles_base_places_pieces_and_exports_walkables(self):
        with tempfile.TemporaryDirectory() as d:
            save(d, "wall.png", solid(30, 20, (10, 20, 30, 255)))
            save(d, "crate.png", solid(10, 8, (200, 100, 0, 255)))
            layout = {"size": [100, 40], "base": {"image": "wall.png", "y": 20},
                      "pieces": [{"image": "crate.png", "x": 50, "y": 12, "walkable": True}]}
            lp = os.path.join(d, "layout.json"); json.dump(layout, open(lp, "w"))
            out = os.path.join(d, "gameplay.png")
            compose_plate.main([lp, "-o", out])
            px = np.asarray(Image.open(out))
            self.assertEqual(px.shape[:2], (40, 100))
            self.assertEqual(px[5, 5, 3], 0)                           # above the base: transparent
            self.assertEqual(tuple(px[30, 95, :3]), (10, 20, 30))      # wall tiled to the right edge
            self.assertEqual(tuple(px[15, 55, :3]), (200, 100, 0))     # crate placed
            walk = json.load(open(os.path.join(d, "gameplay_collision.json")))
            self.assertEqual(walk, [[50, 12, 10, 8]])

    def test_loop_wraps_pieces_across_the_edge(self):
        with tempfile.TemporaryDirectory() as d:
            save(d, "pillar.png", solid(20, 10, (255, 255, 255, 255)))
            layout = {"size": [100, 10], "loop": True,
                      "pieces": [{"image": "pillar.png", "x": 90, "y": 0}]}
            lp = os.path.join(d, "layout.json"); json.dump(layout, open(lp, "w"))
            out = os.path.join(d, "fg_loop.png")
            compose_plate.main([lp, "-o", out])
            px = np.asarray(Image.open(out))
            self.assertEqual(px[5, 95, 3], 255)   # right part of the pillar
            self.assertEqual(px[5, 5, 3], 255)    # wrapped onto the left edge
            self.assertEqual(px[5, 50, 3], 0)


class LoopSeamTest(unittest.TestCase):
    def test_wrap_then_unwrap_round_trips(self):
        with tempfile.TemporaryDirectory() as d:
            a = np.zeros((4, 10, 4), np.uint8); a[..., 3] = 255; a[:, :, 0] = np.arange(10)[None, :] * 20
            p = save(d, "near_loop.png", Image.fromarray(a))
            loop_seam.main(["wrap", p])
            wrapped = os.path.join(d, "near_loop_wrapped.png")
            self.assertEqual(int(np.asarray(Image.open(wrapped))[0, 0, 0]), 100)  # old middle now at the edge
            loop_seam.main(["unwrap", wrapped, "-o", p])
            self.assertTrue((np.asarray(Image.open(p)) == a).all())

    def test_check_flags_a_hard_seam(self):
        with tempfile.TemporaryDirectory() as d:
            smooth = np.zeros((8, 16, 4), np.uint8); smooth[..., 3] = 255
            smooth[..., 0] = (np.sin(np.arange(16) / 16 * 2 * np.pi) * 100 + 120)[None, :]
            ok = save(d, "ok.png", Image.fromarray(smooth))
            hard = smooth.copy(); hard[:, :8, 0] = 0; hard[:, 8:, 0] = 250
            bad = save(d, "bad.png", Image.fromarray(hard))
            self.assertEqual(loop_seam.main(["check", ok]), 0)
            self.assertEqual(loop_seam.main(["check", bad]), 1)


if __name__ == "__main__":
    unittest.main()
