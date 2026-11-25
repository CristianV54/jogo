# Enche a ilha: sorteia lugares para povoados novos e traça a Estrada da Costa (um anel ligando as vilas de fora) e ramais,
# conferindo que nada cai no mar, em cima de rio, dentro de região ou colado em outro povoado. Lê a planta de
# scripts/mundo/mundo_dados.gd e ESCREVE nela (bloco entre as marcas "# >>> GERADO" e "# <<< GERADO"). Rodar de novo
# troca o bloco inteiro (mesma semente = mesmo resultado).
#   python3 tools/mundo/encher_o_mundo.py
import re, math, random, sys
ARQ = "scripts/mundo/mundo_dados.gd"
s = open(ARQ, encoding="utf-8").read()
s = re.sub(r"\t# >>> GERADO.*?# <<< GERADO[^\n]*\n", "", s, flags=re.S)   # tira o que foi gerado antes
V = lambda t: [(float(a), float(b)) for a, b in re.findall(r"Vector2\((-?[\d.]+), (-?[\d.]+)\)", t)]
ex, ez = map(float, re.search(r"EIXOS_DA_ILHA := Vector2\(([\d.]+), ([\d.]+)\)", s).groups())
regioes = [(float(a), float(b), float(c)) for a, b, c in re.findall(r'"centro": Vector2\((-?[\d.]+), (-?[\d.]+)\), "meia": ([\d.]+)', s)]
rios = [V(t) for t in re.findall(r'"fundo": [\d.]+,\s*"pontos": \[(.*?)\]\}', s, flags=re.S)]
estradas = {i: V(t) for i, t in re.findall(r'\{"id": "(\w+)", "nome": "[^"]+", "a".*?"pontos": \[(.*?)\]\}', s, flags=re.S)}
povoados = [(float(x), float(z), float(r), t) for t, x, z, r in re.findall(r'"tipo": "(\w+)", "centro": Vector2\((-?[\d.]+), (-?[\d.]+)\), "dir".*?"raio": ([\d.]+)', s)]
reino = tuple(map(float, re.search(r'REINO := \{"centro": Vector2\((-?[\d.]+), (-?[\d.]+)\), "raio": ([\d.]+)\}', s).groups()))
print("lido:", len(regioes), "regiões,", len(rios), "rios,", len(estradas), "estradas,", len(povoados), "povoados")

def costa(x, z):   # distância até o mar (sem o ruído fino de 30 m: por isso as folgas abaixo são largas)
    n = math.hypot(x / ex, z / ez); ang = math.atan2(z / ez, x / ex)
    borda = 1 + 0.045 * math.sin(ang * 3 + 0.6) + 0.03 * math.sin(ang * 5 + 2.1) + 0.017 * math.sin(ang * 9 + 4.0)
    return (borda - n) / math.hypot(math.cos(ang) / ex, math.sin(ang) / ez)

def d_seg(p, a, b):
    vx, vz = b[0] - a[0], b[1] - a[1]; L = vx * vx + vz * vz
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vz) / L))
    return math.hypot(p[0] - a[0] - vx * t, p[1] - a[1] - vz * t)

def d_linha(p, pts): return min(d_seg(p, pts[i], pts[i + 1]) for i in range(len(pts) - 1))
def d_regiao(p): return min(math.hypot(max(abs(p[0] - cx) - m, 0), max(abs(p[1] - cz) - m, 0)) for cx, cz, m in regioes)

def cruza(a, b, c, d):
    o = lambda p, q, r: (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0

def cruza_rio(a, b): return any(cruza(a, b, r[i], r[i + 1]) for r in rios for i in range(len(r) - 1))

NOMES = {
    "vila": ["Vila Riacho Fundo", "Vila Carvalhal", "Vila Monte Claro", "Vila Serra Baixa", "Vila Lagoa Seca", "Vila Pedra Lisa", "Vila Vento Sul", "Vila Ribeira",
             "Vila Bom Retiro", "Vila Areal", "Vila Morro Verde", "Vila Sete Pontes", "Vila Córrego Frio", "Vila Cruz das Almas"],
    "fazenda": ["Fazenda Boa Vista", "Fazenda do Vale", "Fazenda Capim Dourado", "Fazenda Olho d'Água", "Fazenda Pedregal", "Fazenda Rio Manso", "Fazenda Cerca Velha",
                "Fazenda Girassol", "Fazenda Arado", "Fazenda Colmeia", "Fazenda Remanso", "Fazenda Espiga", "Fazenda Curral Novo", "Fazenda Açude", "Fazenda Horizonte", "Fazenda Sombra Boa"],
    "cabana": ["Cabana do Ermitão", "Cabana do Caçador", "Cabana da Clareira", "Cabana do Barqueiro", "Cabana do Mateiro", "Cabana da Colina", "Cabana do Ferreiro Velho", "Cabana do Vigia"],
    "posto": ["Posto da Encruzilhada", "Posto do Desfiladeiro", "Posto da Mata", "Posto do Morro", "Posto da Ponte"],
    "posto_imperial": ["Estalagem do Viajante", "Estalagem da Encosta", "Estalagem das Três Estradas", "Estalagem do Rio"],
    "pescador": ["Cabana do Pescador do Oeste", "Cabana do Pescador do Leste", "Cabana do Pescador do Sul", "Cabana do Pescador da Baía"],
}
RAIO = {"vila": 70, "fazenda": 55, "cabana": 40, "posto": 40, "posto_imperial": 50, "pescador": 22}
rng = random.Random(2026)
novos = []   # (id, nome, tipo, x, z)
todos = list(povoados)
for tipo in ["vila", "posto_imperial", "fazenda", "posto", "cabana", "pescador"]:
    for nome in NOMES[tipo]:
        for tentativa in range(4000):
            x = rng.uniform(-ex, ex); z = rng.uniform(-ez, ez); p = (x, z); c = costa(x, z)
            if tipo == "pescador":
                if not (110 < c < 190): continue
            elif c < 260: continue
            if d_regiao(p) < 260 or min(d_linha(p, r) for r in rios) < 110: continue
            if math.hypot(x - reino[0], z - reino[1]) < reino[2] + 220: continue   # fora da muralha do reino, com folga
            if min(d_linha(p, e) for e in estradas.values()) < RAIO[tipo] + 45: continue
            folga = 620 if tipo == "vila" else 300
            if any(math.hypot(x - q[0], z - q[1]) < (folga if (tipo == "vila" and q[3] == "vila") else 300) for q in todos): continue
            if tipo == "vila" and d_regiao(p) < 520: continue
            novos.append((re.sub(r"[^a-z]+", "_", nome.lower().replace("á", "a").replace("ã", "a").replace("ó", "o").replace("é", "e").replace("ç", "c").replace("í", "i").replace("ê", "e")).strip("_"), nome, tipo, round(x), round(z)))
            todos.append((x, z, RAIO[tipo], tipo)); break
        else:
            print("SEM LUGAR para", nome)

# ---- Estrada da Costa: anel pelas vilas de fora, em trechos de vila a vila
vilas = [(q[0], q[1], q[2]) for q in todos if q[3] == "vila" and math.hypot(q[0] / ex, q[1] / ez) > 0.56]   # só as vilas de fora (bairros do reino não entram)
vilas.sort(key=lambda q: math.atan2(q[1], q[0]))
novas_estradas = []
def livre(pts, a, b):
    for i in range(len(pts) - 1):
        for k in range(41):
            p = (pts[i][0] + (pts[i + 1][0] - pts[i][0]) * k / 40, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * k / 40)
            if d_regiao(p) < 60 or costa(*p) < 120: return False
            if any(math.hypot(p[0] - q[0], p[1] - q[1]) < q[2] + 35 for q in todos if (q[0], q[1]) not in ((a[0], a[1]), (b[0], b[1]))): return False
    return True
for i, a in enumerate(vilas):
    b = vilas[(i + 1) % len(vilas)]
    L = math.hypot(b[0] - a[0], b[1] - a[1]); ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    ini = (a[0] + ux * a[2] * 0.85, a[1] + uz * a[2] * 0.85); fim = (b[0] - ux * b[2] * 0.85, b[1] - uz * b[2] * 0.85)
    for desvio in (0, 160, -160, 380, -380, 650, -650):
        meio = ((ini[0] + fim[0]) / 2 - uz * (desvio + rng.uniform(-50, 50)), (ini[1] + fim[1]) / 2 + ux * (desvio + rng.uniform(-50, 50)))
        pts = [ini, meio, fim]
        if livre(pts, a, b):
            novas_estradas.append(("costa_%02d" % (len(novas_estradas) + 1), "Estrada da Costa", pts)); break
    else:
        print("anel: sem caminho livre entre", (round(a[0]), round(a[1])), "e", (round(b[0]), round(b[1])))
tudo_estradas = dict(estradas); tudo_estradas.update({i: p for i, _, p in novas_estradas})

# ---- cada povoado novo sai por uma trilha até a estrada mais perto que não exija atravessar rio
linhas = []
for pid, nome, tipo, x, z in novos:
    de_fora = {k: v for k, v in tudo_estradas.items() if not k.startswith(("travessa_", "rua_do_meio", "anel_do_reino"))}   # rua de dentro da muralha não serve: a trilha atravessaria a pedra
    opcoes = sorted(de_fora.items(), key=lambda kv: d_linha((x, z), kv[1]))
    liga = ""
    for eid, pts in opcoes[:4]:
        perto = min(((pts[i][0] + (pts[i + 1][0] - pts[i][0]) * k / 20, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * k / 20) for i in range(len(pts) - 1) for k in range(21)), key=lambda q: math.hypot(q[0] - x, q[1] - z))
        if not cruza_rio((x, z), perto):
            liga = eid; break
    linhas.append('\t{"id": "%s", "nome": "%s", "tipo": "%s", "centro": Vector2(%d, %d), "dir": Vector2(1, 0), "lado": 1.0, "raio": %.1f, "liga": "%s"},' % (pid, nome, tipo, x, z, RAIO[tipo], liga))
bloco_p = "\t# >>> GERADO por tools/mundo/encher_o_mundo.py (NOMES PROVISÓRIOS, a aprovar): não editar à mão\n" + "\n".join(linhas) + "\n\t# <<< GERADO\n"
fv = lambda p: "Vector2(%d, %d)" % (round(p[0]), round(p[1]))
bloco_e = "\t# >>> GERADO por tools/mundo/encher_o_mundo.py: a Estrada da Costa, em trechos de vila a vila\n" + "\n".join(
    '\t{"id": "%s", "nome": "%s", "a": "", "b": "", "meia": 20.0,\n\t\t"pontos": [%s]},' % (i, n, ", ".join(fv(p) for p in pts)) for i, n, pts in novas_estradas) + "\n\t# <<< GERADO\n"
a = s.index("const POVOADOS_LIVRES := ["); f = s.index("\n]\n", a) + 1
s = s[:f] + bloco_p + s[f:]
a = s.index("const ESTRADAS := ["); f = s.index("\n]\n", a) + 1
s = s[:f] + bloco_e + s[f:]
open(ARQ, "w", encoding="utf-8").write(s)
print("povoados novos:", len(novos), " trechos da Estrada da Costa:", len(novas_estradas), " total de povoados:", len(todos), " estradas:", len(tudo_estradas))
print("sem trilha (rio no caminho):", [l.split('"')[3] for l in linhas if l.endswith('"liga": ""},')])
