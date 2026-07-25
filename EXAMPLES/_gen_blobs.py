import os, base64, lzma

SRC = r"C:\Users\mr.smith\STM32F401CCU6-Blink-Bare-Metal"
OUT = r"C:\Users\mr.smith\stm32codegen\EXAMPLES"

files = {
    "Makefile": os.path.join(SRC, "Makefile"),
    "LD": os.path.join(SRC, "STM32F401CCUX_FLASH.ld"),
    "jdebug": os.path.join(SRC, "project.jdebug"),
    "jflash": os.path.join(SRC, "stm32f401cc.jflash"),
    "keil": os.path.join(SRC, "ide", "MDK-ARM", "Project.uvprojx"),
}

for name, path in files.items():
    with open(path, "rb") as f:
        raw = f.read()
    compressed = lzma.compress(raw)
    b64 = base64.b64encode(compressed).decode("ascii")
    outfile = os.path.join(OUT, f"_blob_{name}.txt")
    with open(outfile, "w") as f:
        f.write(b64)
    print(f"{name}: {len(raw)} raw, {len(compressed)} compressed, {len(b64)} base64")
    print(f"  -> {outfile}")

print("Done!")