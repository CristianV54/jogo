# Monta a GALERIA: junta as fotos de tudo o que o jogo tem em folhas por categoria, com o nome de cada coisa.
# Entradas: as tiras da bancada de itens (tools/bancada.gd), as fotos das peças de construção
# (tools/bancada_construcao.gd) e as fotos de dentro do mundo (capturar_reino, capturar_ilha, capturar_mapa).
# Saída: docs/galeria/<NN>_<categoria>_<k>.jpg.   Uso: python3 tools/montar_galeria.py
import os, glob, sys
from PIL import Image, ImageDraw, ImageFont
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
BANCADA = '/Users/faresrames/Desktop/ajustes' if os.path.isdir('/Users/faresrames/Desktop/ajustes') else os.path.join(RAIZ, 'tools/capturas/bancada')
SAIDA = os.path.join(RAIZ, 'docs/galeria')
os.makedirs(SAIDA, exist_ok=True)
for velho in glob.glob(os.path.join(SAIDA, '*.jpg')):
    os.remove(velho)
try:
    FONTE = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 22)
    TITULO = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 34)
except OSError:
    FONTE = TITULO = ImageFont.load_default()

def folhas(prefixo, titulo, itens, colunas, larg, alt, por_folha):
    """itens: lista de (nome, caminho). Cada célula tem `larg` x `alt` e uma faixa com o nome por baixo."""
    feitas = 0
    for k in range(0, len(itens), por_folha):
        lote = itens[k:k + por_folha]
        linhas = (len(lote) + colunas - 1) // colunas
        folha = Image.new('RGB', (colunas * larg, 60 + linhas * (alt + 34)), (24, 22, 20))
        d = ImageDraw.Draw(folha)
        d.text((16, 10), '%s  (%d de %d)' % (titulo, k // por_folha + 1, (len(itens) + por_folha - 1) // por_folha), font=TITULO, fill=(240, 225, 190))
        for i, (nome, caminho) in enumerate(lote):
            x, y = (i % colunas) * larg, 60 + (i // colunas) * (alt + 34)
            im = Image.open(caminho).convert('RGB')
            im.thumbnail((larg - 6, alt))
            folha.paste(im, (x + (larg - im.width) // 2, y))
            d.text((x + 10, y + alt + 4), nome, font=FONTE, fill=(235, 235, 230))
        folha.save(os.path.join(SAIDA, '%s_%d.jpg' % (prefixo, k // por_folha + 1)), quality=86)
        feitas += 1
    print('%-28s %3d fotos em %d folhas' % (prefixo, len(itens), feitas))

def tiras(cat):
    return sorted((os.path.basename(os.path.dirname(c)), c) for c in glob.glob(os.path.join(BANCADA, cat, '*', 'depois.jpg')))
def fotos(padrao):
    return [(os.path.basename(c)[:-4].replace('_', ' '), c) for c in sorted(glob.glob(os.path.join(RAIZ, padrao)))]

folhas('01_personagens', 'PERSONAGENS (frente, lado, costas)', tiras('personagens'), 2, 1120, 280, 14)
folhas('02_animais', 'ANIMAIS', tiras('animais'), 2, 1120, 280, 14)
folhas('03_criaturas_e_inimigos', 'CRIATURAS E INIMIGOS', tiras('criaturas') + tiras('inimigos'), 2, 1120, 280, 14)
folhas('04_tubarao', 'TUBARÃO (bancada e dentro do mar)', fotos('docs/validacao/tubarao/*.jpg'), 3, 853, 480, 9)
folhas('05_armas_e_drops', 'ARMAS E ITENS QUE CAEM', tiras('armas') + tiras('drops'), 2, 1120, 280, 16)
folhas('06_moveis', 'MÓVEIS E OBJETOS', tiras('moveis'), 3, 840, 210, 30)
folhas('07_natureza', 'NATUREZA', tiras('natureza'), 2, 1120, 280, 14)
folhas('08_pecas_de_casa', 'PEÇAS DE CASA (kit das vilas)', tiras('pecas_de_casa'), 4, 840, 210, 48)
for n, (peca, nome) in enumerate([('muralha', 'MURALHA'), ('rua', 'RUA'), ('feira', 'FEIRA'), ('catedral', 'CATEDRAL'), ('quartel', 'QUARTEL'), ('acampamento', 'ACAMPAMENTO E BARCO')]):
    folhas('1%d_construcao_%s' % (n, peca), 'CONSTRUÇÃO: ' + nome + ' (na bancada)', fotos('tools/capturas/construcao/%s/*.jpg' % peca), 3, 853, 480, 9)
reino = fotos('tools/capturas/reino/*.jpg')
folhas('20_valdoria', 'VALDORIA, DENTRO DO JOGO', [f for f in reino if f[0][:2] < '20'], 3, 853, 480, 9)
folhas('21_povoados', 'VILAS, FAZENDAS, PESCADOR E POSTOS', [f for f in reino if '20' <= f[0][:2] < '30'], 3, 853, 480, 9)
folhas('22_montanha_e_estradas', 'MONTANHA DOS DRAGÕES, PONTE E TUBARÃO', [f for f in reino if f[0][:2] >= '30'], 3, 853, 480, 9)
folhas('23_ilha_e_mapa', 'A ILHA DE CIMA, O CHÃO E O MAPA', fotos('tools/capturas/ilha/*.jpg'), 3, 853, 480, 9)
