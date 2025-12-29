

Q = 3329
ZETA = 17
N = 256

def bitRev7(x: int) -> int:
    """Đảo bit 7-bit (0 <= x < 128)."""
    r = 0
    for _ in range(7):
        r = (r << 1) | (x & 1)
        x >>= 1
    return r

def ntt(f):
    """
    Forward NTT (độ dài 256) 
    f: list/tuple độ dài 256, phần tử trong [0..Q-1]
    """
    q = Q
    zeta = ZETA

    f_hat = [x % q for x in f]  # copy + mod q
    i = 1  # 1-based 

    length = 128
    while length >= 2:
        step = 2 * length
        for start in range(0, N, step):
            # exp = bitRev7(i) 
            exp = bitRev7(i)
            zeta_pow = pow(zeta, exp, q)
            i += 1

            for j in range(start, start + length):
                t = (zeta_pow * f_hat[j + length]) % q
                u = f_hat[j]
                f_hat[j + length] = (u - t) % q
                f_hat[j] = (u + t) % q
        length //= 2

    return f_hat

def BaseCaseMultiply(a0, a1, b0, b1, gamma):
    """Nhân hai đa thức bậc 1 mod (X^2 - gamma), mod q. Trả về (c0, c1)."""
    q = Q
    c0 = (a0 * b0 + a1 * b1 * gamma) % q
    c1 = (a0 * b1 + a1 * b0) % q
    return c0, c1

def MultiplyNTTs(f_hat, g_hat):
    """Nhân hai biểu diễn NTT f_hat, g_hat (mỗi list dài 256) trong T_q."""
    q = Q
    zeta = ZETA
    h_hat = [0] * N

    for i in range(128):
        br = bitRev7(i)
        exponent = 2 * br + 1
        gamma = pow(zeta, exponent, q)

        c0, c1 = BaseCaseMultiply(
            f_hat[2 * i],     f_hat[2 * i + 1],
            g_hat[2 * i],     g_hat[2 * i + 1],
            gamma
        )
        h_hat[2 * i] = c0
        h_hat[2 * i + 1] = c1

    return h_hat

def intt256_inplace(poly):
    """Inverse NTT (Kyber style), in-place."""
    q = Q
    zeta = ZETA
    inv128 = 3303  # 128^{-1} mod q

    poly = [x % q for x in poly]

    i = 127  
    length = 2
    while length <= 128:
        step = 2 * length
        for start in range(0, N, step):
            br = bitRev7(i)
            zeta_power = pow(zeta, br, q)
            i -= 1

            for j in range(start, start + length):
                t = poly[j]
                u = poly[j + length]
                poly[j] = (t + u) % q
                poly[j + length] = (zeta_power * ((u - t) % q)) % q
        length *= 2

    poly = [(x * inv128) % q for x in poly]
    return poly

# -------------------- I/O helpers --------------------

def _parse_token(tok: str) -> int:
    """Chuyển 1 token thành int. Hỗ trợ thập phân, '0x...' hoặc hexa trần ('1a3')."""
    s = tok.strip().lower().rstrip(',')  # bỏ dấu phẩy nếu có
    if s.startswith('0x'):
        return int(s, 16)
    # nếu có ký tự a-f => coi là hex
    if any(c in s for c in 'abcdef'):
        return int(s, 16)
    return int(s, 10)

def read_vector(path: str) -> list:
    """Đọc 256 số từ file, cách nhau bởi khoảng trắng hoặc xuống dòng."""
    with open(path, 'r', encoding='utf-8') as f:
        data = f.read().replace('\r', ' ')
    toks = data.replace('\n', ' ').split()
    vec = [_parse_token(t) for t in toks]
    if len(vec) != N:
        raise ValueError(f"{path}: cần đúng {N} số, nhưng đọc được {len(vec)}.")
    return [x % Q for x in vec]

def write_vector_decimal(path: str, vec: list):
    """Ghi mỗi phần tử trên 1 dòng, thập phân."""
    if len(vec) != N:
        raise ValueError(f"Output length must be {N}. Got {len(vec)}.")
    with open(path, 'w', encoding='utf-8') as f:
        for x in vec:
            f.write(f"{int(x)%Q}\n")

# -------------------- Main --------------------

def main():
    f = read_vector('input_f.txt')
    g = read_vector('input_g.txt')

    f_hat = ntt(f)
    g_hat = ntt(g)

    write_vector_decimal('output_ntt_f.txt', f_hat)
    write_vector_decimal('output_ntt_g.txt', g_hat)

    # Nếu bạn muốn kiểm tra nhân & INTT, bỏ comment bên dưới:
    # h_hat = MultiplyNTTs(f_hat, g_hat)
    # h = intt256_inplace(h_hat)
    # write_vector_decimal('output_hhat.txt', h_hat)
    # write_vector_decimal('output_h.txt', h)

if __name__ == "__main__":
    main()
