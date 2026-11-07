# Topic pictures in Bahasa Melayu

The app ships with the original topic pictures, whose banners read
"Maths for Primary Students", "Maths for Secondary Students",
"Maths for Higher Education" and "Tourism Melaka".

This folder holds the same four pictures with the banner text in Bahasa
Melayu:

| File | Banner text |
| --- | --- |
| `topic_maths_primary.png` | Matematik Sekolah Rendah |
| `topic_maths_secondary.png` | Matematik Sekolah Menengah |
| `topic_maths_higher.png` | Matematik Pengajian Tinggi |
| `topic_tourism_melaka.png` | Pelancongan Melaka |

This folder is not listed under `assets` in `pubspec.yaml`, so these files
are not packed into the app.

## Switch to the Bahasa Melayu pictures

From the project folder:

```bash
cp design/topic_images_bm/*.png assets/images/topics/
```

Then rebuild the app.

## Switch back to the English pictures

```bash
git checkout -- assets/images/topics/topic_maths_primary.png \
  assets/images/topics/topic_maths_secondary.png \
  assets/images/topics/topic_maths_higher.png \
  assets/images/topics/topic_tourism_melaka.png
```

That restores the pictures from the last commit, which has the English
ones. Then rebuild the app.

The file names stay the same either way, so no code changes are needed.
The topic names in the rest of the app are in Bahasa Melayu regardless of
which pictures are used.
