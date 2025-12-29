# ---------- Kyber INTT (N=256) chỉ ghi kết quả cuối ----------

Q = 3329
ZETA = 17
N = 256
INV128 = 3303  # 128^{-1} mod Q

def bitRev7(x: int) -> int:
    r = 0
    for _ in range(7):
        r = (r << 1) | (x & 1)
        x >>= 1
    return r

def intt_inplace(poly):
    """INTT in-place (Kyber, N=256)."""
    a = [x % Q for x in poly]

    i = 127
    length = 2
    while length <= 128:
        step = 2 * length
        for start in range(0, N, step):
            exp = bitRev7(i)
            zpow = pow(ZETA, exp, Q)
            i -= 1

            for j in range(start, start + length):
                t = a[j]
                s = (t + a[j + length]) % Q
                d = (a[j + length] - t) % Q
                a[j] = s
                a[j + length] = (zpow * d) % Q

        length *= 2

    # nhân nghịch đảo của 128
    a = [(x * INV128) % Q for x in a]
    return a

# --------- IO helpers ----------
def _parse_token(tok: str) -> int:
    s = tok.strip().lower().rstrip(',')
    if s.startswith('0x'):
        return int(s, 16)
    if any(c in s for c in 'abcdef'):
        return int(s, 16)
    return int(s, 10)

def read_vector(path: str) -> list:
    with open(path, 'r', encoding='utf-8') as f:
        data = f.read().replace('\r', ' ')
    toks = data.replace('\n', ' ').split()
    vec = [_parse_token(t) for t in toks]
    if len(vec) != N:
        raise ValueError(f"{path}: cần đúng {N} số, nhưng đọc được {len(vec)}.")
    return [x % Q for x in vec]

def write_result(path: str, vec: list):
    """Ghi kết quả cuối: mỗi dòng một số."""
    with open(path, 'w', encoding='utf-8') as f:
        for x in vec:
            f.write(f"{x}\n")

# --------- ví dụ chạy ----------
def main():
    a_hat = read_vector('input_hat.txt')     # 256 hệ số miền NTT
    a = intt_inplace(a_hat)
    write_result('output_intt.txt', a)

if __name__ == "__main__":
    main()
