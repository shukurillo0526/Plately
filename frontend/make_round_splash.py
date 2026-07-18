from PIL import Image, ImageDraw
import os

def make_circular(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    
    # Create high-res mask for anti-aliasing (4x supersampling)
    scale = 4
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, w * scale - 1, h * scale - 1), fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    
    # Apply mask to image
    output = img.copy()
    output.putalpha(mask)
    output.save(output_path, "PNG")
    print(f"Created circular icon: {output_path} ({w}x{h})")

# 1. Update assets/icon/splash_icon.png
if not os.path.exists("assets/icon/splash_icon_square.png"):
    if os.path.exists("assets/icon/splash_icon.png"):
        Image.open("assets/icon/splash_icon.png").save("assets/icon/splash_icon_square.png")

make_circular("assets/icon/splash_icon_square.png", "assets/icon/splash_icon.png")

# 2. Update all web splash images
web_sizes = [
    ("1x", 128),
    ("2x", 256),
    ("3x", 384),
    ("4x", 512)
]

for suffix, size in web_sizes:
    base = Image.open("assets/icon/splash_icon.png").resize((size, size), Image.Resampling.LANCZOS)
    for theme in ["light", "dark"]:
        path = f"web/splash/img/{theme}-{suffix}.png"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        base.save(path, "PNG")
        print(f"Updated {path}")

print("All splash icons converted to circular mask with transparent corners!")
