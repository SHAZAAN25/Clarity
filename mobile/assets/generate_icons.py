import zlib
import struct
import math
import os

def write_png(filename, width, height, rgba_data):
    raw_rows = []
    for y in range(height):
        start = y * width * 4
        end = start + width * 4
        raw_rows.append(b'\x00' + rgba_data[start:end])
    raw_data = b''.join(raw_rows)
    compressed = zlib.compress(raw_data, 9)

    png = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    png += struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)

    idat_crc = zlib.crc32(b'IDAT' + compressed)
    png += struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)

    iend_crc = zlib.crc32(b'IEND')
    png += struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'wb') as f:
        f.write(png)
    print(f"Generated {filename} ({width}x{height})")

def point_to_segment_dist(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(px - x1, py - y1)
    t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.hypot(px - proj_x, py - proj_y)

def point_to_bezier_dist(px, py, p0, p1, p2, p3, steps=32):
    # Sample points along cubic bezier to compute min distance
    min_dist = float('inf')
    for i in range(steps + 1):
        t = i / float(steps)
        inv = 1.0 - t
        bx = inv**3 * p0[0] + 3 * inv**2 * t * p1[0] + 3 * inv * t**2 * p2[0] + t**3 * p3[0]
        by = inv**3 * p0[1] + 3 * inv**2 * t * p1[1] + 3 * inv * t**2 * p2[1] + t**3 * p3[1]
        dist = math.hypot(px - bx, py - by)
        if dist < min_dist:
            min_dist = dist
    return min_dist

def sample_icon_at(x, y, size, transparent_bg):
    cx, cy = size / 2.0, size / 2.0
    dx = x - cx
    dy = y - cy
    dist = math.hypot(dx, dy)
    angle = math.atan2(dy, dx) # in [-pi, pi]

    # Logo scale parameters
    r_loop = size * 0.25
    stroke_w = size * 0.052

    # Bezier curve for ascending breakthrough release
    # Releasing upward-right into open clarity
    p0 = (cx - size * 0.03, cy + size * 0.03)
    p1 = (cx + size * 0.05, cy - size * 0.12)
    p2 = (cx + size * 0.15, cy - size * 0.22)
    p3 = (cx + size * 0.27, cy - size * 0.25)

    # Accent dot position
    dot_x = cx - size * 0.09
    dot_y = cy - size * 0.14
    dot_r = stroke_w * 0.58

    if transparent_bg:
        r_bg, g_bg, b_bg, a_bg = 0, 0, 0, 0
    else:
        # Deep obsidian sage background (#121916 to #151A19)
        norm_d = min(1.0, dist / (size * 0.7))
        r_bg = int(18 + 3 * (1.0 - norm_d))
        g_bg = int(24 + 4 * (1.0 - norm_d))
        b_bg = int(22 + 3 * (1.0 - norm_d))
        a_bg = 255

    r, g, b, a = r_bg, g_bg, b_bg, a_bg

    # 1. Arc: sweeping from bottom (approx 0.45*pi) clockwise to upper left (-0.75*pi)
    # The gap/break is in the upper right (-0.75*pi to 0.45*pi is preserved, gap is -0.75*pi to 0.45*pi? Wait)
    # Angle: atan2(dy, dx): bottom is +pi/2 (1.57), left is +pi/-pi, top is -pi/2 (-1.57), right is 0.
    # In Flutter: math.pi * 0.45 to math.pi * 1.40.
    # Flutter 0 is right (0 deg), 0.5*pi is bottom, pi is left, 1.5*pi is top (-0.5*pi in atan2).
    # Flutter sweep: 0.45*pi (bottom) to 1.40*pi (top-left).
    # In atan2: 0.45*pi (~1.41) up to pi (~3.14) and -pi down to -0.60*pi (~ -1.88).
    # That is: (angle >= 1.40) or (angle <= -1.88)
    in_arc_angle = (angle >= 1.35) or (angle <= -1.85)

    loop_dist = abs(dist - r_loop)
    if in_arc_angle:
        if loop_dist < stroke_w:
            alpha = max(0.0, min(1.0, 1.0 - (loop_dist / stroke_w)))
            # Primary Sage light #D8F3DC (216, 243, 220)
            r = int(r * (1 - alpha) + 216 * alpha)
            g = int(g * (1 - alpha) + 243 * alpha)
            b = int(b * (1 - alpha) + 220 * alpha)
            a = max(a, int(255 * alpha))
    else:
        # Rounded caps for arc ends
        end1_x = cx + r_loop * math.cos(1.35)
        end1_y = cy + r_loop * math.sin(1.35)
        d1 = math.hypot(x - end1_x, y - end1_y)
        if d1 < stroke_w:
            alpha = max(0.0, min(1.0, 1.0 - (d1 / stroke_w)))
            r = int(r * (1 - alpha) + 216 * alpha)
            g = int(g * (1 - alpha) + 243 * alpha)
            b = int(b * (1 - alpha) + 220 * alpha)
            a = max(a, int(255 * alpha))

        end2_x = cx + r_loop * math.cos(-1.85)
        end2_y = cy + r_loop * math.sin(-1.85)
        d2 = math.hypot(x - end2_x, y - end2_y)
        if d2 < stroke_w:
            alpha = max(0.0, min(1.0, 1.0 - (d2 / stroke_w)))
            r = int(r * (1 - alpha) + 216 * alpha)
            g = int(g * (1 - alpha) + 243 * alpha)
            b = int(b * (1 - alpha) + 220 * alpha)
            a = max(a, int(255 * alpha))

    # 2. Ascending breakthrough curve (Sage emerald #52B788)
    bez_dist = point_to_bezier_dist(x, y, p0, p1, p2, p3)
    if bez_dist < stroke_w:
        alpha = max(0.0, min(1.0, 1.0 - (bez_dist / stroke_w)))
        # Emerald primary #52B788 (82, 183, 136)
        r = int(r * (1 - alpha) + 82 * alpha)
        g = int(g * (1 - alpha) + 183 * alpha)
        b = int(b * (1 - alpha) + 136 * alpha)
        a = max(a, int(255 * alpha))

    # 3. Harmonic accent dot
    dot_dist = math.hypot(x - dot_x, y - dot_y)
    if dot_dist < dot_r:
        alpha = max(0.0, min(1.0, (dot_r - dot_dist) / 1.5))
        r = int(r * (1 - alpha) + 82 * alpha)
        g = int(g * (1 - alpha) + 183 * alpha)
        b = int(b * (1 - alpha) + 136 * alpha)
        a = max(a, int(255 * alpha))

    return r, g, b, a

def render_clarity_icon(size, transparent_bg=False, round_mask=False):
    pixels = bytearray(size * size * 4)
    cx, cy = size / 2.0, size / 2.0
    r_mask = size * 0.48

    # 2x2 subpixel antialiasing
    sub_offsets = [(-0.25, -0.25), (0.25, -0.25), (-0.25, 0.25), (0.25, 0.25)]

    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4

            if round_mask:
                dist_c = math.hypot(x - cx, y - cy)
                if dist_c > r_mask + 0.5:
                    pixels[idx] = 0
                    pixels[idx + 1] = 0
                    pixels[idx + 2] = 0
                    pixels[idx + 3] = 0
                    continue

            acc_r, acc_g, acc_b, acc_a = 0, 0, 0, 0
            for ox, oy in sub_offsets:
                sr, sg, sb, sa = sample_icon_at(x + ox, y + oy, size, transparent_bg)
                acc_r += sr
                acc_g += sg
                acc_b += sb
                acc_a += sa

            fr = acc_r // 4
            fg = acc_g // 4
            fb = acc_b // 4
            fa = acc_a // 4

            if round_mask:
                dist_c = math.hypot(x - cx, y - cy)
                if dist_c > r_mask - 0.5:
                    edge_alpha = max(0.0, min(1.0, r_mask + 0.5 - dist_c))
                    fa = int(fa * edge_alpha)

            pixels[idx] = fr
            pixels[idx + 1] = fg
            pixels[idx + 2] = fb
            pixels[idx + 3] = fa

    return bytes(pixels)

def main():
    root = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(root)
    base_res = os.path.join(project_root, "android", "app", "src", "main", "res")

    densities = {
        "mipmap-mdpi": (48, 108),
        "mipmap-hdpi": (72, 162),
        "mipmap-xhdpi": (96, 216),
        "mipmap-xxhdpi": (144, 324),
        "mipmap-xxxhdpi": (192, 432),
    }

    # 1. Generate standard square/squircle icons and round icons for each density
    for folder, (icon_sz, fg_sz) in densities.items():
        dir_path = os.path.join(base_res, folder)
        os.makedirs(dir_path, exist_ok=True)

        # Standard icon
        std_data = render_clarity_icon(icon_sz, transparent_bg=False, round_mask=False)
        write_png(os.path.join(dir_path, "ic_launcher.png"), icon_sz, icon_sz, std_data)

        # Round icon (for launchers that query roundIcon)
        rnd_data = render_clarity_icon(icon_sz, transparent_bg=False, round_mask=True)
        write_png(os.path.join(dir_path, "ic_launcher_round.png"), icon_sz, icon_sz, rnd_data)

        # Adaptive icon foreground
        fg_data = render_clarity_icon(fg_sz, transparent_bg=True, round_mask=False)
        write_png(os.path.join(dir_path, "ic_launcher_foreground.png"), fg_sz, fg_sz, fg_data)

    # 2. Store / asset icons
    store_sizes = [48, 96, 192, 512]
    app_icon_dir = os.path.join(root, "app_icon")
    os.makedirs(app_icon_dir, exist_ok=True)
    for sz in store_sizes:
        data = render_clarity_icon(sz, transparent_bg=False, round_mask=False)
        write_png(os.path.join(app_icon_dir, f"app_icon_{sz}.png"), sz, sz, data)

    # Adaptive foreground asset for reference
    fg_512 = render_clarity_icon(512, transparent_bg=True, round_mask=False)
    write_png(os.path.join(app_icon_dir, "app_icon_foreground.png"), 512, 512, fg_512)

    print("All launcher and store icons generated successfully.")

if __name__ == '__main__':
    main()
