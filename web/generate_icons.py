import math
from PIL import Image, ImageDraw

def draw_quadcopter(size):
    # Transparent background, monochrome white/cyan design with padding
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = size / 2.0
    cy = size / 2.0
    s = size / 100.0  # scale factor for a 100x100 grid

    color = (0, 229, 255, 255) # Cyan / monochrome accent
    white = (240, 246, 252, 255)
    bg_dark = (18, 24, 32, 255)

    # Optional background disc for app icons (rounded square / dark pill)
    padding = 6 * s
    draw.rounded_rectangle([padding, padding, size - padding, size - padding], radius=18 * s, fill=bg_dark)

    arm_width = max(2, int(3.5 * s))
    prop_width = max(1, int(2.5 * s))

    arm_len = 26 * s
    motor_radius = 5 * s
    prop_radius = 11 * s

    # 4 arms at 45, 135, 225, 315 degrees
    angles = [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4]

    for a in angles:
        mx = cx + arm_len * math.cos(a)
        my = cy + arm_len * math.sin(a)

        # Draw arm
        draw.line([(cx, cy), (mx, my)], fill=white, width=arm_width)

        # Draw motor mount
        draw.ellipse([mx - motor_radius, my - motor_radius, mx + motor_radius, my + motor_radius], fill=bg_dark, outline=color, width=max(1, int(2 * s)))

        # Draw props (2 angled blades)
        pa1 = a + math.pi / 2
        pa2 = a - math.pi / 2
        p1x = mx + prop_radius * math.cos(pa1)
        p1y = my + prop_radius * math.sin(pa1)
        p2x = mx + prop_radius * math.cos(pa2)
        p2y = my + prop_radius * math.sin(pa2)
        draw.arc([mx - prop_radius, my - prop_radius, mx + prop_radius, my + prop_radius], start=math.degrees(a) + 30, end=math.degrees(a) + 150, fill=color, width=prop_width)
        draw.arc([mx - prop_radius, my - prop_radius, mx + prop_radius, my + prop_radius], start=math.degrees(a) + 210, end=math.degrees(a) + 330, fill=color, width=prop_width)

    # Center fuselage / frame
    body_radius = 11 * s
    draw.rounded_rectangle([cx - body_radius, cy - body_radius, cx + body_radius, cy + body_radius], radius=4 * s, fill=color)

    # Center camera lens / crosshair
    cam_r = 4.5 * s
    draw.ellipse([cx - cam_r, cy - cam_r, cx + cam_r, cy + cam_r], fill=bg_dark)
    cross_r = 2.0 * s
    draw.ellipse([cx - cross_r, cy - cross_r, cx + cross_r, cy + cross_r], fill=color)

    # Direction marker (front arrow on top)
    arrow_tip_y = cy - body_radius - 4 * s
    draw.polygon([(cx, arrow_tip_y), (cx - 3 * s, cy - body_radius + 1), (cx + 3 * s, cy - body_radius + 1)], fill=white)

    return img

if __name__ == "__main__":
    import os
    base_dir = "/home/khronos/Flutter-STUDIO/apps/fpv_freq_manager/web"
    icons_dir = os.path.join(base_dir, "icons")
    os.makedirs(icons_dir, exist_ok=True)

    draw_quadcopter(64).save(os.path.join(base_dir, "favicon.png"))
    draw_quadcopter(192).save(os.path.join(icons_dir, "Icon-192.png"))
    draw_quadcopter(512).save(os.path.join(icons_dir, "Icon-512.png"))
    draw_quadcopter(192).save(os.path.join(icons_dir, "Icon-maskable-192.png"))
    draw_quadcopter(512).save(os.path.join(icons_dir, "Icon-maskable-512.png"))
    print("Icons generated successfully!")
