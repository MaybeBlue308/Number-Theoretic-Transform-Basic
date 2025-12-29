# convert_hex_to_decimal.py
def to_u16_dec(h: str) -> int:
    """Chuyển chuỗi hex về số nguyên decimal (0..65535)."""
    val = int(h, 16)  # parse hex
    return val % (1 << 16)

def main(in_path="hex.txt", out_path="outdec.txt"):
    # Đọc toàn bộ file đầu vào
    with open(in_path, "r", encoding="utf-8") as f:
        content = f.read().strip()

    # Tách các số theo dấu cách hoặc xuống dòng
    tokens = content.split()

    out_dec = []
    for idx, tok in enumerate(tokens, start=1):
        try:
            val = to_u16_dec(tok)
        except ValueError:
            raise ValueError(f"Số hex thứ {idx}: không hợp lệ -> '{tok}'")
        out_dec.append(str(val))

    # Ghi file đầu ra (mỗi số một dòng)
    with open(out_path, "w", encoding="utf-8") as f:
        for dec in out_dec:
            f.write(dec + "\n")

    print(f"Đã ghi {len(out_dec)} số decimal vào '{out_path}'")

if __name__ == "__main__":
    main()
