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

def render_clarity_icon(size, transparent_bg=False):
    pixels = bytearray(size * size * 4)
    cx, cy = size / 2.0, size / 2.0

    # Geometry coordinates
    r_loop = size * 0.36
    w_loop = size * 0.075

    lx1 = cx - size * 0.20
    ly1 = cy + size * 0.20
    lx2 = cx + size * 0.32
    ly2 = cy - size * 0.32
    w_line = size * 0.07

    r_center = size * 0.11

    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            # angle in [-pi, pi]
            angle = math.atan2(dy, dx)

            if transparent_bg:
                r, g, b, a = 0, 0, 0, 0
            else:
                # Deep calm charcoal/sage #121916 to #1B2622
                norm_d = min(1.0, dist / (size * 0.65))
                r = int(18 + 7 * (1.0 - norm_d))
                g = int(25 + 11 * (1.0 - norm_d))
                b = int(22 + 9 * (1.0 - norm_d))
                a = 255

            # 1. Broken loop: angle open in upper right (~ -0.9 to 0.1 radians)
            # We open from -pi/4 - 0.45 to -pi/4 + 0.45
            is_open_angle = (-1.25 < angle < -0.15)
            loop_dist = abs(dist - r_loop)
            if loop_dist < w_loop and not is_open_angle:
                alpha = max(0.0, min(1.0, 1.0 - (loop_dist / w_loop)))
                # Sage primary #52B788 (82, 183, 136)
                r = int(r * (1 - alpha) + 82 * alpha)
                g = int(g * (1 - alpha) + 183 * alpha)
                b = int(b * (1 - alpha) + 136 * alpha)
                a = max(a, int(255 * alpha))

            # 2. Diagonal ascending breakthrough vector: from bottom-left to top-right through the break
            line_dist = point_to_segment_dist(x, y, lx1, ly1, lx2, ly2)
            if line_dist < w_line:
                alpha_line = max(0.0, min(1.0, 1.0 - (line_dist / w_line)))
                # Deep forest emerald #2D6A4F (45, 106, 79)
                r = int(r * (1 - alpha_line) + 45 * alpha_line)
                g = int(g * (1 - alpha_line) + 106 * alpha_line)
                b = int(b * (1 - alpha_line) + 79 * alpha_line)
                a = max(a, int(255 * alpha_line))

            # 3. Center calm focal dot: #D8F3DC (216, 243, 220)
            if dist < r_center:
                alpha_dot = max(0.0, min(1.0, (r_center - dist) / 1.5))
                r = int(r * (1 - alpha_dot) + 216 * alpha_dot)
                g = int(g * (1 - alpha_dot) + 243 * alpha_dot)
                b = int(b * (1 - alpha_dot) + 220 * alpha_dot)
                a = max(a, int(255 * alpha_dot))

            pixels[idx] = r
            pixels[idx + 1] = g
            pixels[idx + 2] = b
            pixels[idx + 3] = a

    return bytes(pixels)

def main():
    root = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(root)
    base_res = os.path.join(project_root, "android", "app", "src", "main", "res")

    sizes = {
        os.path.join(base_res, "mipmap-mdpi", "ic_launcher.png"): 48,
        os.path.join(base_res, "mipmap-hdpi", "ic_launcher.png"): 72,
        os.path.join(base_res, "mipmap-xhdpi", "ic_launcher.png"): 96,
        os.path.join(base_res, "mipmap-xxhdpi", "ic_launcher.png"): 144,
        os.path.join(base_res, "mipmap-xxxhdpi", "ic_launcher.png"): 192,
        os.path.join(root, "app_icon", "app_icon_512.png"): 512,
        os.path.join(root, "app_icon", "app_icon_192.png"): 192,
        os.path.join(root, "app_icon", "app_icon_96.png"): 96,
        os.path.join(root, "app_icon", "app_icon_48.png"): 48,
    }

    for path, sz in sizes.items():
        data = render_clarity_icon(sz, transparent_bg=False)
        write_png(path, sz, sz, data)

    # Adaptive foreground
    fg_data = render_clarity_icon(432, transparent_bg=True)
    write_png(os.path.join(base_res, "mipmap-xxxhdpi", "ic_launcher_foreground.png"), 432, 432, fg_data)
    write_png(os.path.join(root, "app_icon", "app_icon_foreground.png"), 432, 432, fg_data)

    print("All launcher and store icons generated successfully.")

if __name__ == '__main__':
    main()
