from PIL import Image, ImageDraw
import os

def crop_and_mask_plate():
    # Load ultra high-res 2048x2048 icon.png or 512x512 splash_icon_square.png
    if os.path.exists("assets/icon/icon.png"):
        src = Image.open("assets/icon/icon.png").convert("RGBA")
        # In 2048x2048, the inner white circular plate runs from ~352 to ~1696 (width 1344, center 1024, radius 672)
        # Let's crop exactly the inner white circular plate (removing all orange borders and outer padding)
        center = 1024
        radius = 668  # slightly inside 672 to ensure no orange border edge bleeding
        box = (center - radius, center - radius, center + radius, center + radius)
    else:
        src = Image.open("assets/icon/splash_icon_square.png").convert("RGBA")
        center = 256
        radius = 167
        box = (center - radius, center - radius, center + radius, center + radius)

    cropped = src.crop(box)
    w, h = cropped.size
    
    # Create ultra high-res circular mask for smooth anti-aliasing
    scale = 4
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, w * scale - 1, h * scale - 1), fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    
    cropped.putalpha(mask)
    
    # Save as 512x512 for splash_icon.png
    final_512 = cropped.resize((512, 512), Image.Resampling.LANCZOS)
    final_512.save("assets/icon/splash_icon.png", "PNG")
    print("Created pure white round plate icon at assets/icon/splash_icon.png (512x512)")
    
    # Update all web splash sizes (128, 256, 384, 512)
    web_sizes = [
        ("1x", 128),
        ("2x", 256),
        ("3x", 384),
        ("4x", 512)
    ]

    for suffix, size in web_sizes:
        resized = cropped.resize((size, size), Image.Resampling.LANCZOS)
        for theme in ["light", "dark"]:
            path = f"web/splash/img/{theme}-{suffix}.png"
            os.makedirs(os.path.dirname(path), exist_ok=True)
            resized.save(path, "PNG")
            print(f"Updated {path} ({size}x{size})")

if __name__ == "__main__":
    crop_and_mask_plate()
    print("Pure white circular plate cropped and updated across all splash assets!")
