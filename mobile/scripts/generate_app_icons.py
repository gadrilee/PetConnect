import os
import shutil
from PIL import Image, ImageDraw

def create_icons():
    workspace_root = r"c:\Users\HP\Downloads\IHC\PetConnect"
    src_logo = os.path.join(workspace_root, "logo_visual.jpeg")
    mobile_dir = os.path.join(workspace_root, "mobile")
    assets_icon_dir = os.path.join(mobile_dir, "assets", "icon")
    res_dir = os.path.join(mobile_dir, "android", "app", "src", "main", "res")
    ios_icon_dir = os.path.join(mobile_dir, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

    os.makedirs(assets_icon_dir, exist_ok=True)

    # Clean up any test preview files
    for f in os.listdir(assets_icon_dir):
        if f.startswith("test_"):
            try:
                os.remove(os.path.join(assets_icon_dir, f))
            except Exception:
                pass

    orig_img = Image.open(src_logo).convert("RGB")
    shutil.copy2(src_logo, os.path.join(assets_icon_dir, "logo_visual.jpeg"))

    # Bounding box of the actual logo artwork (tight crop without white borders)
    # min_x: 92, max_x: 922, min_y: 171, max_y: 848
    bbox = (88, 165, 926, 852)
    art_crop = orig_img.crop(bbox)

    # 1. Zoom/Scale factor: 80% of the canvas
    fill_scale = 0.80
    canvas_size = 1024
    target_w = int(canvas_size * fill_scale)
    target_h = int(target_w * (art_crop.height / art_crop.width))
    scaled_art = art_crop.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    offset_x = (canvas_size - target_w) // 2
    offset_y = (canvas_size - target_h) // 2

    # Master full icon (white background)
    master_icon = Image.new("RGB", (canvas_size, canvas_size), (255, 255, 255))
    master_icon.paste(scaled_art, (offset_x, offset_y))
    master_icon.save(os.path.join(assets_icon_dir, "app_icon.png"), "PNG", quality=100)

    # 2. Adaptive Icon Foreground (transparent background, zoomed artwork)
    art_crop_rgba = orig_img.convert("RGBA").crop(bbox)
    # Floodfill outside white area to transparent
    # Note: floodfill from the 4 corners
    ImageDraw.floodfill(art_crop_rgba, (0, 0), (255, 255, 255, 0), thresh=25)
    ImageDraw.floodfill(art_crop_rgba, (art_crop_rgba.width - 1, 0), (255, 255, 255, 0), thresh=25)
    ImageDraw.floodfill(art_crop_rgba, (0, art_crop_rgba.height - 1), (255, 255, 255, 0), thresh=25)
    ImageDraw.floodfill(art_crop_rgba, (art_crop_rgba.width - 1, art_crop_rgba.height - 1), (255, 255, 255, 0), thresh=25)

    scaled_art_rgba = art_crop_rgba.resize((target_w, target_h), Image.Resampling.LANCZOS)
    fg_img = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 0))
    fg_img.paste(scaled_art_rgba, (offset_x, offset_y), scaled_art_rgba)
    fg_img.save(os.path.join(assets_icon_dir, "app_icon_foreground.png"), "PNG")

    # 3. Round Legacy Icon
    round_icon_img = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 0))
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.ellipse((10, 10, canvas_size - 10, canvas_size - 10), fill=255)
    round_icon_img.paste(master_icon.convert("RGBA"), (0, 0), mask)

    # 4. Android Densities
    android_densities = {
        "mdpi": (48, 108),
        "hdpi": (72, 162),
        "xhdpi": (96, 216),
        "xxhdpi": (144, 324),
        "xxxhdpi": (192, 432),
    }

    for density, (legacy_size, fg_size) in android_densities.items():
        # mipmap folder
        mipmap_folder = os.path.join(res_dir, f"mipmap-{density}")
        os.makedirs(mipmap_folder, exist_ok=True)
        
        # ic_launcher.png (legacy standard)
        std = master_icon.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS)
        std.save(os.path.join(mipmap_folder, "ic_launcher.png"), "PNG")

        # ic_launcher_round.png (legacy round)
        rnd = round_icon_img.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS)
        rnd.save(os.path.join(mipmap_folder, "ic_launcher_round.png"), "PNG")

        # ic_launcher_foreground.png (adaptive foreground)
        fg = fg_img.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
        fg.save(os.path.join(mipmap_folder, "ic_launcher_foreground.png"), "PNG")

        # Also save to drawable-* to ensure both references work
        drawable_folder = os.path.join(res_dir, f"drawable-{density}")
        os.makedirs(drawable_folder, exist_ok=True)
        fg.save(os.path.join(drawable_folder, "ic_launcher_foreground.png"), "PNG")

    # 5. Android Adaptive Icon XML (without excessive inset so it fills the icon)
    anydpi_dir = os.path.join(res_dir, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)

    adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    # 6. iOS Icons
    ios_sizes = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]

    os.makedirs(ios_icon_dir, exist_ok=True)
    for filename, size in ios_sizes:
        ios_icon = master_icon.resize((size, size), Image.Resampling.LANCZOS)
        ios_icon.save(os.path.join(ios_icon_dir, filename), "PNG")

    print("Icons successfully regenerated with 90% zoom fill!")

if __name__ == "__main__":
    create_icons()
