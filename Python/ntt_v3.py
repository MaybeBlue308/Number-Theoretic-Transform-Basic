Q = 3329
ZETA = 17
N = 256

# LUT zeta values for Kyber NTT
ZETAS_TABLE = [
    1,1729,2580,3289,2642,630,1897,848,
    1062,1919,193,797,2786,3260,569,1746,
    296,2447,1339,1476,3046,56,2240,1333,
    1426,2094,535,2882,2393,2879,1974,821,
    289,331,3253,1756,1197,2304,2277,2055,
    650,1977,2513,632,2865,33,1320,1915,
    2319,1435,807,452,1438,2868,1534,2402,
    2647,2617,1481,648,2474,3110,1227,910,
    17,2761,583,2649,1637,723,2288,1100,
    1409,2662,3281,233,756,2156,3015,3050,
    1703,1651,2789,1789,1847,952,1461,2687,
    939,2308,2437,2388,733,2337,268,641,
    1584,2298,2037,3220,375,2549,2090,1645,
    1063,319,2773,757,2099,561,2466,2594,
    2804,1092,403,1026,1143,2150,2775,886,
    1722,1212,1874,1029,2110,2935,885,2154
]

def bitRev7(x: int) -> int:
    r = 0
    for _ in range(7):
        r = (r << 1) | (x & 1)
        x >>= 1
    return r

def ntt(f):
    q = Q
    zeta = ZETA

    f_hat = [x % q for x in f]
    zeta_map = [(None, None, None)] * N  # (exp, zpow, pos)
    i = 1

    length = 128
    while length >= 2:
        step = 2 * length
        for start in range(0, N, step):
            exp = bitRev7(i)
            zeta_pow = pow(zeta, exp, q)
            i += 1

            # finding position in ZETAS_TABLE
            pos = None
            if zeta_pow in ZETAS_TABLE:
                pos = ZETAS_TABLE.index(zeta_pow)

            for j in range(start, start + length):
                t = (zeta_pow * f_hat[j + length]) % q
                u = f_hat[j]
                f_hat[j + length] = (u - t) % q
                f_hat[j] = (u + t) % q

                zeta_map[j] = (exp, zeta_pow, pos)
                zeta_map[j + length] = (exp, zeta_pow, pos)

        length //= 2

    return f_hat, zeta_map

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

def write_vector_with_zeta(path: str, vec: list, zeta_map: list):
    with open(path, 'w', encoding='utf-8') as f:
        for i, x in enumerate(vec):
            exp, zpow, pos = zeta_map[i]
            if exp is None:
                f.write(f"{i:3d}: {x}\n")
            else:
                f.write(f"{i:3d}: {x:5d}   (zeta^{exp} = {zpow}, pos={pos})\n")

def main():
    f = read_vector('input_f.txt')
    g = read_vector('input_g.txt')

    f_hat, f_map = ntt(f)
    g_hat, g_map = ntt(g)

    write_vector_with_zeta('output_ntt_f_v3.txt', f_hat, f_map)
    write_vector_with_zeta('output_ntt_g_v3.txt', g_hat, g_map)

if __name__ == "__main__":
    main()
