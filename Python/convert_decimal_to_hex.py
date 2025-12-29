# convert_decimal_to_hex.py
def to_u16_hex(n: int) -> str:
    """Chuyển số nguyên n về hex 16-bit, zero-pad 4 ký tự, in hoa."""
    n = n % (1 << 16)  # hỗ trợ cả số âm/ngoài phạm vi bằng modulo 2^16
    return f"{n:04X}"

def main(in_path="decimal.txt", out_path="outhex.txt"):
    # Đọc toàn bộ file đầu vào (1 dòng chứa nhiều số cách nhau bằng dấu cách)
    with open(in_path, "r", encoding="utf-8") as f:
        content = f.read().strip()

    # Tách các số theo dấu cách
    tokens = content.split()
    
    out_hex = []
    for idx, tok in enumerate(tokens, start=1):
        try:
            val = int(tok, 10)
        except ValueError:
            raise ValueError(f"Số thứ {idx}: không phải số decimal hợp lệ -> '{tok}'")
        out_hex.append(to_u16_hex(val))

    # Ghi file đầu ra (mỗi số một dòng)
    with open(out_path, "w", encoding="utf-8") as f:
        for hx in out_hex:
            f.write(hx + "\n")

    print(f"Đã ghi {len(out_hex)} số hex vào '{out_path}'")

if __name__ == "__main__":
    main()
