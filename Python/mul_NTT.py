# ntt_multiply_pairwise.py
# Thực hiện MultiplyNTTs : base-case deg-1 theo cặp (2i, 2i+1)
# h_hat = MultiplyNTTs(f_hat, g_hat)
# Đọc:  input_f_hat.txt, input_g_hat.txt
# Ghi:  output_h_hat.txt

from typing import List

Q = 3329
ZETA = 17  # primitive 256-th root of unity theo code MATLAB đã đưa

def read_vec(path: str) -> List[int]:
    """Đọc 256 số nguyên từ file; chấp nhận phân tách bằng whitespace hoặc dấu phẩy."""
    with open(path, "r", encoding="utf-8") as f:
        txt = f.read()
    tokens = [t for t in txt.replace(",", " ").split() if t.strip() != ""]
    vec = [int(t) % Q for t in tokens]
    return vec

def write_vec(path: str, vec: List[int]) -> None:
    """Ghi mỗi phần tử trên một dòng."""
    with open(path, "w", encoding="utf-8") as f:
        for x in vec:
            f.write(f"{x}\n")

def bitrev7(x: int) -> int:
    """Đảo bit 7-bit (0 <= x < 128) giống MATLAB bitRev7."""
    r = 0
    for _ in range(7):
        r = (r << 1) | (x & 1)
        x >>= 1
    return r  # 0..127

def base_case_multiply(a0: int, a1: int, b0: int, b1: int, gamma: int) -> (int, int):
    """c0 = a0*b0 + a1*b1*gamma (mod q); c1 = a0*b1 + a1*b0 (mod q)."""
    a0 %= Q; a1 %= Q; b0 %= Q; b1 %= Q; gamma %= Q
    c0 = (a0 * b0 + (a1 * b1 % Q) * gamma) % Q
    c1 = (a0 * b1 + a1 * b0) % Q
    return c0, c1

def multiply_ntts(f_hat: List[int], g_hat: List[int]) -> List[int]:
    """Thực hiện đúng MultiplyNTTs : duyệt i=0..127, dùng gamma = zeta^(2*br+1)."""
    if len(f_hat) != len(g_hat):
        raise ValueError(f"Length mismatch: len(f_hat)={len(f_hat)} vs len(g_hat)={len(g_hat)}")
    if len(f_hat) != 256:
        raise ValueError(f"Expected length 256, got {len(f_hat)}")

    h_hat = [0] * 256
    for i in range(128):
        br = bitrev7(i)
        exponent = 2 * br + 1
        gamma = pow(ZETA, exponent, Q)

        a0 = f_hat[2*i]     # chú ý: Python index 0-based (tương ứng MATLAB (2*i+1))
        a1 = f_hat[2*i + 1] # (tương ứng MATLAB (2*i+2))
        b0 = g_hat[2*i]
        b1 = g_hat[2*i + 1]

        c0, c1 = base_case_multiply(a0, a1, b0, b1, gamma)
        h_hat[2*i]     = c0
        h_hat[2*i + 1] = c1
    return h_hat

def main():
    f_hat = read_vec("input_f_hat.txt")
    g_hat = read_vec("input_g_hat.txt")
    h_hat = multiply_ntts(f_hat, g_hat)
    write_vec("output_h_hat.txt", h_hat)
    print(f"OK: wrote {len(h_hat)} values to output_h_hat.txt")

if __name__ == "__main__":
    main()
