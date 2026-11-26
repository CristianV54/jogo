# Gera TODOS os sons do jogo por síntese (nenhum arquivo baixado): passos, golpe, acerto, dano, coleta, asas, rugido,
# aviso do tubarão, vento, mar, grilos, pássaros e a música de fundo. Saída: assets/audio/*.wav (22050 Hz, mono, 16 bits).
# Os laços (vento, mar, grilos, música) fecham sem estalo: o fim é misturado com o começo.
#   python3 tools/audio/gerar_sons.py
import numpy as np, wave, os
SR = 22050
rng = np.random.default_rng(7)
SAIDA = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'audio')

def gravar(nome, s, pico=0.85):
    s = np.asarray(s, dtype=np.float64)
    s = s - s.mean()
    m = np.abs(s).max()
    if m > 0:
        s = s / m * pico
    with wave.open(os.path.join(SAIDA, nome + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((s * 32767).astype('<i2').tobytes())
    print('%-16s %5.2f s' % (nome, len(s) / SR))

def t(seg): return np.arange(int(seg * SR)) / SR
def ruido(seg): return rng.standard_normal(int(seg * SR))
def passa_baixa(x, corte):   # um polo, corte em Hz (pode ser um vetor: corte que varia no tempo)
    a = 1.0 - np.exp(-2 * np.pi * np.broadcast_to(np.asarray(corte, dtype=float), x.shape) / SR)
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc); y[i] = acc
    return y
def passa_alta(x, corte): return x - passa_baixa(x, corte)
def cai(seg, tau): return np.exp(-t(seg) / tau)
def sino(seg): return np.sin(np.pi * t(seg) / seg) ** 2
def laco(x, emenda=0.5):   # mistura o fim com o começo para o laço fechar sem estalo
    n = int(emenda * SR); corpo = x[:-n].copy(); rampa = np.linspace(0, 1, n)
    corpo[:n] = corpo[:n] * rampa + x[-n:] * (1 - rampa)
    return corpo

# --- passos: terra (surdo), pedra (seco e claro), casco de cavalo
for k in range(3):
    d = 0.14
    gravar('passo_terra_%d' % k, passa_baixa(ruido(d), 500 + 150 * k) * cai(d, 0.03) + 0.6 * np.sin(2 * np.pi * (85 + 8 * k) * t(d)) * cai(d, 0.025), 0.7)
    gravar('passo_pedra_%d' % k, passa_alta(passa_baixa(ruido(d), 2600 + 300 * k), 500) * cai(d, 0.018) + 0.3 * np.sin(2 * np.pi * (140 + 10 * k) * t(d)) * cai(d, 0.02), 0.7)
d = 0.16
gravar('casco', passa_alta(passa_baixa(ruido(d), 1800), 300) * cai(d, 0.02) + 0.8 * np.sin(2 * np.pi * 160 * t(d)) * cai(d, 0.03), 0.8)
# --- espada no ar: chiado cuja cor sobe; acerto: baque grave com estalo; dano no Torin: pancada e um tom que desce
d = 0.3
gravar('golpe', passa_alta(passa_baixa(ruido(d), np.linspace(500, 3200, int(d * SR))), 350) * sino(d) ** 1.5, 0.75)
d = 0.22
gravar('acerto', np.sin(2 * np.pi * np.cumsum(np.linspace(150, 55, int(d * SR))) / SR) * cai(d, 0.06) + 0.7 * passa_baixa(ruido(d), 3000) * cai(d, 0.012))
d = 0.35
gravar('dano', np.sin(2 * np.pi * np.cumsum(np.linspace(220, 110, int(d * SR))) / SR) * cai(d, 0.1) + 0.5 * passa_baixa(ruido(d), 900) * cai(d, 0.03))
# --- pegar item: duas notas claras; morte: três notas que descem; aviso do tubarão: duas notas graves e tensas
def nota(freq, seg, tau, harm=(1.0, 0.35, 0.12)):
    return sum(a * np.sin(2 * np.pi * freq * (i + 1) * t(seg)) for i, a in enumerate(harm)) * cai(seg, tau)
def juntar(partes, total):
    s = np.zeros(int(total * SR))
    for inicio, som in partes:
        i = int(inicio * SR); s[i:i + len(som)] += som[:len(s) - i]
    return s
gravar('coletar', juntar([(0.0, nota(659.3, 0.3, 0.09)), (0.09, nota(987.8, 0.4, 0.12))], 0.5), 0.6)
gravar('morte', juntar([(0.0, nota(293.7, 0.9, 0.35)), (0.35, nota(246.9, 0.9, 0.35)), (0.7, nota(196.0, 1.4, 0.5))], 2.2), 0.7)
gravar('aviso', juntar([(0.0, nota(82.4, 0.5, 0.25, (1, 0.6, 0.4, 0.2))), (0.45, nota(87.3, 0.9, 0.4, (1, 0.6, 0.4, 0.2)))], 1.4), 0.8)
# --- asa de dragão batendo; rugido: serra grave que treme, com sopro
d = 0.55
gravar('asa', passa_baixa(ruido(d), np.linspace(700, 180, int(d * SR))) * sino(d), 0.8)
d = 1.8
fase = 2 * np.pi * np.cumsum(72 + 9 * np.sin(2 * np.pi * 23 * t(d)) + np.linspace(25, -15, int(d * SR))) / SR
serra = 2 * ((fase / (2 * np.pi)) % 1.0) - 1
gravar('rugido', (passa_baixa(serra, 650) + 0.5 * passa_baixa(ruido(d), 900)) * (1 + 0.35 * np.sin(2 * np.pi * 31 * t(d))) * sino(d) ** 0.6, 0.9)
# --- pássaros: três cantos (trinados que sobem e descem)
for k, (f0, f1, n, passo) in enumerate([(2600, 3900, 4, 0.11), (3300, 2500, 3, 0.16), (2900, 4400, 6, 0.07)]):
    partes = []
    for i in range(n):
        dd = passo * 0.8
        partes.append((i * passo, np.sin(2 * np.pi * np.cumsum(np.linspace(f0, f1, int(dd * SR))) / SR) * sino(dd)))
    gravar('passaro_%d' % k, juntar(partes, n * passo + 0.1), 0.45)
# --- laços de ambiente
d = 9.0
vento = passa_baixa(ruido(d), 420 + 260 * np.sin(2 * np.pi * t(d) / 4.25)) * (0.65 + 0.35 * np.sin(2 * np.pi * t(d) / 2.83 + 1.0))
gravar('vento', laco(vento), 0.6)
d = 12.5
onda = np.clip(np.sin(2 * np.pi * t(d) / 6.0), 0, 1) ** 1.5
gravar('mar', laco(passa_baixa(ruido(d), 500 + 1400 * onda) * (0.25 + 0.75 * onda)), 0.7)
d = 4.5
pulso = (np.sin(2 * np.pi * 34 * t(d)) > 0.2) * (np.sin(2 * np.pi * t(d) / 0.8) > -0.3)
gravar('grilos', laco(np.sin(2 * np.pi * 4300 * t(d)) * passa_baixa(pulso.astype(float), 600) + 0.6 * np.sin(2 * np.pi * 4750 * t(d)) * passa_baixa(np.roll(pulso, 4000).astype(float), 600)), 0.3)
# --- música: alaúde (corda dedilhada de Karplus-Strong) sobre um pedal grave, em ré dórico, 66 batidas por minuto
def corda(freq, seg, brilho=0.5):
    n = int(SR / freq); buf = rng.uniform(-1, 1, n); buf = passa_baixa(buf, 1500 + 5000 * brilho)
    s = np.empty(int(seg * SR))
    for i in range(len(s)):
        s[i] = buf[i % n]; buf[i % n] = 0.996 * 0.5 * (buf[i % n] + buf[(i + 1) % n])
    return s
RE = {'D2': 73.42, 'A2': 110.0, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61, 'G3': 196.0, 'A3': 220.0, 'B3': 246.94, 'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.0, 'A4': 440.0}
tempo = 60.0 / 66.0
frases = ['D3 A3 D4 F4 E4 D4 A3 -', 'G3 D4 G4 F4 E4 D4 B3 -', 'F3 C4 F4 E4 D4 C4 A3 -', 'D3 A3 D4 E4 F4 E4 D4 -',
          'A3 E4 A4 G4 F4 E4 D4 -', 'G3 D4 G4 E4 D4 B3 G3 -', 'F3 A3 C4 F4 E4 C4 A3 -', 'D3 A3 D4 A3 F3 D3 A2 -']
total = len(frases) * 8 * tempo
partes = []
for f, frase in enumerate(frases):
    for i, n in enumerate(frase.split()):
        if n != '-':
            partes.append(((f * 8 + i) * tempo, 0.8 * corda(RE[n], 2.4, 0.35 + 0.1 * (i % 3))))
    baixo = frase.split()[0][0] + '2' if frase.split()[0][0] in 'DA' else 'D2'
    partes.append((f * 8 * tempo, 0.9 * corda(RE.get(baixo, RE['D2']), 6.0, 0.1)))
musica = juntar(partes, total + 3.0)
pedal = (np.sin(2 * np.pi * 73.42 * t(total + 3.0)) + 0.6 * np.sin(2 * np.pi * 110.2 * t(total + 3.0)) + 0.4 * np.sin(2 * np.pi * 146.5 * t(total + 3.0))) * (0.75 + 0.25 * np.sin(2 * np.pi * t(total + 3.0) / (4 * tempo)))
gravar('musica', laco(musica + 0.12 * pedal * np.abs(musica).max(), 3.0), 0.7)
