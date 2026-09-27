import json, os, sys, tempfile, unittest
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import check_art, make_maps


def rgba(w, h, color=(0, 0, 0, 0)):
    return Image.new("RGBA", (w, h), color)


class MakeMapsTest(unittest.TestCase):
    def test_flat_image_gives_flat_normal(self):
        n = np.asarray(make_maps.make_normal(rgba(8, 8, (100, 100, 100, 255))))
        self.assertTrue((abs(n[..., 0].astype(int) - 128) <= 1).all())
        self.assertTrue((abs(n[..., 1].astype(int) - 128) <= 1).all())
        self.assertTrue((n[..., 2] >= 254).all())

    def test_brighter_to_the_right_tilts_normal_left(self):
        a = np.zeros((8, 16, 4), np.uint8); a[..., 3] = 255
        a[..., 0:3] = np.linspace(0, 255, 16, dtype=np.uint8)[None, :, None]
        n = np.asarray(make_maps.make_normal(Image.fromarray(a)))
        self.assertLess(int(n[4, 8, 0]), 120)

    def test_emissive_keeps_bright_saturated_drops_grey(self):
        a = np.zeros((1, 2, 4), np.uint8); a[..., 3] = 255
        a[0, 0, :3] = (0, 255, 255)   # bright cyan -> glows
        a[0, 1, :3] = (90, 90, 90)    # grey -> dark
        e = np.asarray(make_maps.make_emissive(Image.fromarray(a), 0.8))
        self.assertGreater(int(e[0, 0, 2]), 200)
        self.assertEqual(int(e[0, 1, :3].max()), 0)

    def test_existing_maps_not_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            src = os.path.join(d, "near.png"); rgba(4, 4, (255, 0, 0, 255)).save(src)
            emit = os.path.join(d, "near_emit.png"); rgba(4, 4, (1, 2, 3, 255)).save(emit)
            make_maps.main([src])
            self.assertEqual(Image.open(emit).getpixel((0, 0)), (1, 2, 3, 255))
            self.assertTrue(os.path.exists(os.path.join(d, "near_n.png")))
            make_maps.main([src, "--force"])
            self.assertNotEqual(Image.open(emit).getpixel((0, 0)), (1, 2, 3, 255))


class CheckArtTest(unittest.TestCase):
    def _char(self, d, size, alpha=True, companions=True):
        cdir = os.path.join(d, "characters", "hero"); os.makedirs(cdir)
        img = rgba(size, size, (0, 0, 0, 0 if alpha else 255)); img.putpixel((0, 0), (9, 9, 9, 255))
        p = os.path.join(cdir, "parts.png"); img.save(p)
        if companions:
            img.save(os.path.join(cdir, "parts_n.png")); img.save(os.path.join(cdir, "parts_emit.png"))
        return p

    def test_good_character_passes(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(check_art.check_file(self._char(d, 2048)), [])

    def test_wrong_size_and_missing_companions_fail(self):
        with tempfile.TemporaryDirectory() as d:
            errs = check_art.check_file(self._char(d, 1000, companions=False))
            self.assertTrue(any("size" in e for e in errs))
            self.assertTrue(any("_n" in e for e in errs))

    def test_plate_size_checked_against_sizes_json(self):
        with tempfile.TemporaryDirectory() as d:
            ldir = os.path.join(d, "levels", "l1"); os.makedirs(ldir)
            json.dump({"far": [64, 32]}, open(os.path.join(ldir, "sizes.json"), "w"))
            p = os.path.join(ldir, "far.png"); rgba(64, 30).save(p)
            self.assertTrue(any("64x32" in e for e in check_art.check_file(p)))

    def test_opaque_non_sky_plate_fails_sky_passes(self):
        with tempfile.TemporaryDirectory() as d:
            ldir = os.path.join(d, "levels", "l1"); os.makedirs(ldir)
            mid = os.path.join(ldir, "mid.png"); rgba(8, 8, (5, 5, 5, 255)).save(mid)
            sky = os.path.join(ldir, "sky.png"); rgba(8, 8, (5, 5, 5, 255)).save(sky)
            self.assertTrue(any("transparen" in e for e in check_art.check_file(mid)))
            self.assertEqual(check_art.check_file(sky), [])


if __name__ == "__main__":
    unittest.main()
