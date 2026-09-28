import json, os, sys, tempfile, time, unittest
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import import_art


def section(d, name="l9_test"):
    s = os.path.join(d, name); os.makedirs(s); return s


class ImportArtTest(unittest.TestCase):
    def test_slices_layers_into_strips_with_manifest_and_import_files(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (5000, 100), (1, 2, 3, 255)).save(os.path.join(s, "gameplay.png"))
            Image.new("RGBA", (5000, 100), (128, 128, 255, 255)).save(os.path.join(s, "gameplay_n.png"))
            Image.new("RGBA", (4096, 50), (0, 0, 0, 0)).save(os.path.join(s, "near_loop.png"))
            Image.new("RGBA", (40, 90), (9, 9, 9, 255)).save(os.path.join(s, "fg_pillar.png"))
            self.assertEqual(import_art.main([d]), 1)
            strips = os.path.join(s, "_strips")
            m = json.load(open(os.path.join(strips, "manifest.json")))
            self.assertEqual(m["gameplay"]["widths"], [2048, 2048, 904])
            self.assertTrue(m["gameplay"]["has_n"])
            self.assertFalse(m["gameplay"]["has_emit"])
            self.assertEqual(m["near_loop"]["widths"], [2048, 2048])
            self.assertEqual(m["props"], ["fg_pillar.png"])
            self.assertEqual(Image.open(os.path.join(strips, "gameplay_02.png")).size, (904, 100))
            imp = open(os.path.join(strips, "gameplay_n_02.png.import")).read()
            for line in ("compress/mode=2", "compress/normal_map=1", "mipmaps/generate=true"):
                self.assertIn(line, imp)
            self.assertNotIn("normal_map=1", open(os.path.join(strips, "gameplay_00.png.import")).read())

    def test_second_run_skips_unchanged_sections(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (100, 50), (1, 2, 3, 255)).save(os.path.join(s, "far.png"))
            self.assertEqual(import_art.main([d]), 1)
            self.assertEqual(import_art.main([d]), 0)
            time.sleep(0.05)
            Image.new("RGBA", (100, 50), (4, 5, 6, 255)).save(os.path.join(s, "far.png"))
            self.assertEqual(import_art.main([d]), 1)

    def test_reimport_removes_stale_strips(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (5000, 20), (1, 1, 1, 255)).save(os.path.join(s, "near.png"))
            import_art.main([d])
            Image.new("RGBA", (1000, 20), (1, 1, 1, 255)).save(os.path.join(s, "near.png"))
            import_art.main([d, "--force"])
            self.assertFalse(os.path.exists(os.path.join(s, "_strips", "near_02.png")))
            self.assertFalse(os.path.exists(os.path.join(s, "_strips", "near_02.png.import")))

    def test_traces_solid_mask_to_collision_rects(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (200, 100), (0, 0, 0, 0)).save(os.path.join(s, "gameplay.png"))
            mask = Image.new("L", (200, 100), 0)
            mask.paste(255, (0, 80, 200, 100))   # floor
            mask.paste(255, (50, 60, 70, 80))    # crate
            mask.save(os.path.join(s, "gameplay_solid.png"))
            import_art.main([d])
            rects = json.load(open(os.path.join(s, "_strips", "collision_traced.json")))
            self.assertEqual(rects, [[50, 60, 20, 20], [0, 80, 200, 20]])

    def test_deleted_source_triggers_reimport(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (100, 50), (0, 0, 0, 0)).save(os.path.join(s, "gameplay.png"))
            mask = Image.new("L", (100, 50), 255); mask.save(os.path.join(s, "gameplay_solid.png"))
            import_art.main([d])
            os.remove(os.path.join(s, "gameplay_solid.png"))
            self.assertEqual(import_art.main([d]), 1)
            self.assertFalse(os.path.exists(os.path.join(s, "_strips", "collision_traced.json")))

    def test_redelivered_file_with_older_timestamp_triggers_reimport(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            far = os.path.join(s, "far.png")
            Image.new("RGBA", (100, 50), (1, 2, 3, 255)).save(far)
            import_art.main([d])
            Image.new("RGBA", (120, 50), (1, 2, 3, 255)).save(far)
            os.utime(far, (1_000_000_000, 1_000_000_000))  # e.g. unzipped art keeps an old date
            self.assertEqual(import_art.main([d]), 1)

    def test_full_size_sources_are_not_imported_by_godot(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            for name in ("gameplay.png", "gameplay_n.png", "fg_pillar.png"):
                Image.new("RGBA", (64, 32), (1, 1, 1, 255)).save(os.path.join(s, name))
            Image.new("L", (64, 32), 255).save(os.path.join(s, "gameplay_solid.png"))
            import_art.main([d])
            for name in ("gameplay.png", "gameplay_n.png", "fg_pillar.png", "gameplay_solid.png"):
                self.assertIn('importer="keep"', open(os.path.join(s, name + ".import")).read(), name)
            self.assertIn("compress/mode=2", open(os.path.join(s, "_strips", "gameplay_00.png.import")).read())


if __name__ == "__main__":
    unittest.main()
