from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    size = 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    shield_outer = [
        (size * 0.2, size * 0.15),
        (size * 0.8, size * 0.15),
        (size * 0.87, size * 0.45),
        (size * 0.5, size * 0.9),
        (size * 0.13, size * 0.45),
    ]
    draw.polygon(shield_outer, fill=(10, 94, 181, 255))

    shield_inner = [
        (size * 0.27, size * 0.22),
        (size * 0.73, size * 0.22),
        (size * 0.78, size * 0.46),
        (size * 0.5, size * 0.83),
        (size * 0.22, size * 0.46),
    ]
    draw.polygon(shield_inner, fill=(20, 132, 233, 255))

    lock_center = (size * 0.5, size * 0.48)
    lock_width = size * 0.3
    lock_height = size * 0.28
    lock_rect = [
        (lock_center[0] - lock_width / 2, lock_center[1] - lock_height / 2 + 60),
        (lock_center[0] + lock_width / 2, lock_center[1] + lock_height / 2 + 60),
    ]
    draw.rounded_rectangle(lock_rect, radius=60, fill=(255, 255, 255, 255))

    shackle_box = [
        (lock_center[0] - lock_width / 3, lock_center[1] - lock_height / 2 - 80),
        (lock_center[0] + lock_width / 3, lock_center[1] - lock_height / 2 + 40),
    ]
    draw.arc(shackle_box, start=0, end=180, width=60, fill=(255, 255, 255, 255))
    draw.rectangle(
        [
            (lock_center[0] - lock_width / 3, lock_center[1] - lock_height / 2 - 10),
            (lock_center[0] + lock_width / 3, lock_center[1] - lock_height / 2 + 40),
        ],
        fill=(255, 255, 255, 255),
    )

    hole_center = (lock_center[0], lock_center[1] + 60)
    draw.ellipse(
        [
            (hole_center[0] - 30, hole_center[1] - 60),
            (hole_center[0] + 30, hole_center[1]),
        ],
        fill=(10, 94, 181, 255),
    )
    draw.rectangle(
        [
            (hole_center[0] - 15, hole_center[1]),
            (hole_center[0] + 15, hole_center[1] + 80),
        ],
        fill=(10, 94, 181, 255),
    )

    font_path = None
    for candidate in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
        if Path(candidate).exists():
            font_path = candidate
            break
    font_large = ImageFont.truetype(font_path, 150) if font_path else ImageFont.load_default()
    font_small = ImageFont.truetype(font_path, 120) if font_path else ImageFont.load_default()

    text_color = (255, 255, 255, 255)
    title = "3:11"
    title_bbox = draw.textbbox((0, 0), title, font=font_large)
    title_width = title_bbox[2] - title_bbox[0]
    draw.text(
        (size / 2 - title_width / 2, size * 0.82),
        title,
        font=font_large,
        fill=text_color,
    )

    subtitle = "SECURITY"
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=font_small)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text(
        (size / 2 - subtitle_width / 2, size * 0.92),
        subtitle,
        font=font_small,
        fill=text_color,
    )

    output_path = Path("assets/images/logo.png")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


if __name__ == "__main__":
    main()

