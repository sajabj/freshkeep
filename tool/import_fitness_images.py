"""Import generated Phase 5.9 recipe photos as optimized offline WebP assets."""

from pathlib import Path
from PIL import Image


SOURCE = Path.home() / ".codex/generated_images/01a15538-47f0-73f2-9e4e-5b1944052f43"
DESTINATION = Path(__file__).resolve().parents[1] / "assets/images/recipes"
FILES = {
    "fitness-chicken-rice-veg": "exec-464c5c2b-97f2-451b-9459-f853382918c9.png",
    "fitness-baked-salmon-potatoes": "exec-99e5c98e-f624-4af3-98d7-620e95b6e7cb.png",
    "fitness-tuna-chickpea-salad": "exec-c060c04a-bb13-4cfa-804f-a4170851aa67.png",
    "fitness-meatballs-bulgur": "exec-1b4dd900-a834-42c0-8466-aa8d22e0b533.png",
    "fitness-spinach-cheese-omelet": "exec-743733b7-8af9-4660-8e54-c450abf66c28.png",
    "fitness-banana-milk-oatmeal": "exec-fbfe5976-7cd2-4a35-8f7d-1ea72d87c56b.png",
    "fitness-peanut-banana-toast": "exec-08b669be-f477-4fd5-84e6-249b39a4e68c.png",
    "fitness-yogurt-fruit-oats": "exec-7969892a-3eaf-4e5e-8623-4a64d9afb264.png",
    "fitness-banana-strawberry-smoothie": "exec-63275fcb-95e6-4da2-95b1-f74b90e153f4.png",
    "fitness-cheese-veg-sandwich": "exec-c9de8f5c-a63f-4891-bc88-9fefe6254cde.png",
    "fitness-chicken-sweet-potato": "exec-b58a2c35-8d02-42c1-b8d3-fa6b5324b6b2.png",
    "fitness-chicken-pea-rice": "exec-a829fc9a-6868-421d-b0c6-751b3ee54681.png",
    "fitness-whole-wheat-tuna-wrap": "exec-3dbc4eba-4514-4693-86d8-c397bdd0e467.png",
    "fitness-lentil-rice-veg-bowl": "exec-76633212-09c8-4404-97ca-612778c6ee22.png",
    "fitness-chicken-tomato-pasta": "exec-3e8487df-f3f0-4b01-b7fc-e2a1e6ef960c.png",
    "fitness-greek-yogurt-berries-nuts": "exec-2d935513-09b2-4e4c-b160-9a0addda0770.png",
    "fitness-roasted-chickpeas": "exec-251b4898-b7ce-42b6-b6d5-44a62526a522.png",
    "fitness-avocado-egg-toast": "exec-70c07218-9610-475f-979d-58e55b73fb19.png",
    "fitness-oat-date-bites": "exec-44c46850-cc7a-413e-921f-32a4dbf23c7c.png",
    "fitness-fruit-yogurt-salad": "exec-4c5cf33b-1e58-4218-ae73-10b383a2a767.png",
}


for recipe_id, filename in FILES.items():
    source = SOURCE / filename
    destination = DESTINATION / f"{recipe_id}.webp"
    with Image.open(source) as image:
        image = image.convert("RGB")
        if image.width > 1200:
            height = round(image.height * 1200 / image.width)
            image = image.resize((1200, height), Image.Resampling.LANCZOS)
        image.save(destination, "WEBP", quality=80, method=6)
    print(f"{destination.name}: {destination.stat().st_size} bytes")
