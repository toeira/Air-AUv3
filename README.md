# Air AUv3 — primeira adaptação para iOS / Codemagic

Projeto de código-fonte, versão 0.1.0. Não é um IPA já compilado.
Reutiliza o núcleo DSP do BlueLab Air 6.2.4 e acrescenta uma extensão AUv3
nativa para iPhone/iPad e uma app que instala essa extensão.

## Compilar no Codemagic

1. Coloca o conteúdo desta pasta na raiz de um repositório Git: `codemagic.yaml`,
   `project.yml`, `Sources`, `scripts` e `tests` devem ficar na raiz.
2. Liga o repositório ao Codemagic e seleciona a configuração `codemagic.yaml`.
3. Executa o workflow **Air AUv3 - IPA para assinatura local**
   (`air-auv3-unsigned`).
4. Se a compilação terminar com sucesso, descarrega
   `Air_AUv3_unsigned.ipa` da secção Artifacts.
5. Assina a app **e a extensão incorporada** usando o teu método de instalação
   local. Um IPA sem assinatura não se instala diretamente num dispositivo
   iOS normal. Os identificadores da app e da extensão devem manter a relação
   `pt.amadeumagalhaes.air` / `pt.amadeumagalhaes.air.auv3` ou uma relação
   equivalente se o programa de assinatura os substituir.
6. Abre a app Air uma vez. No AUM, adiciona o efeito
   **Amadeu: Air (BlueLab DSP)** a um canal de áudio.

O workflow não requer certificados para compilar e não publica na App Store.
Os ficheiros do Xcode são gerados automaticamente com XcodeGen. Todas as
fontes do processamento estão incluídas; não é preciso descarregar o antigo
iPlug2 ou os submódulos desaparecidos da BlueLab.

## Controlos

| Controlo | Intervalo | Função |
|---|---|---|
| Deteção | −120 a 0 dB | Limiar de deteção dos componentes harmónicos |
| Ar / Harmónicos | −100 a +100% | −100: ar/ruído; 0: ambos; +100: harmónicos |
| Saída | −12 a +12 dB | Ganho geral |
| Atuação acima de | 20 a 20 000 Hz | Preserva a zona abaixo do corte; processa acima |
| Ganho processado | −12 a +12 dB | Ganho da zona acima do corte |

O corte efetivo é limitado a 45% da frequência de amostragem. O ganho e a
frequência usam suavização. Os parâmetros são expostos ao host e guardados
através de `fullState`/`fullStateForDocument`. O bypass é o do próprio host.
A app independente apresenta instruções; o processamento acontece no host AUv3.

## Estado de validação e limites

- O núcleo C/C++ compila e foi executado em Linux, em mono e estéreo, a
  44,1 / 48 / 96 kHz, incluindo blocos variáveis de 1 a 4096 amostras.
- O teste inclui áudio com sinusóide e ruído, mudanças de mistura, frequência
  de atuação e ganho, e uma medição da separação da componente de 440 Hz.
- A configuração YAML e os caminhos de fontes foram verificados.
- **A compilação com o SDK iOS, a instalação e o teste no AUM ainda não foram
  executados.** O primeiro build no Codemagic pode revelar ajustes de SDK.
  `build/xcodebuild.log` é incluído nos artefactos para resolver esses erros.
- Esta primeira adaptação usa o modo normal de reconstrução do Air.
  A opção original **Smart Resynthesis** e o gráfico espectral não fazem parte
  desta versão. O algoritmo original `AirProcess3` e o detetor
  `PartialTracker5` estão incluídos.
- Eventos de parâmetros respeitam a posição dentro do bloco. As rampas do host
  usam o valor de destino e a suavização interna; a duração exata da rampa ainda
  não é reproduzida.
- O processamento espectral introduz latência: 2048 amostras a 44,1/48 kHz,
  cerca de 46/43 ms; 4096 a 96 kHz, cerca de 43 ms. A latência é comunicada ao host.
- O código original usa buffers e algumas alocações no processamento. O consumo
  de CPU e o comportamento em tempo real no iPad ainda precisam de validação.
- Formato AUv3 suportado: Float32 não intercalado, 1 ou 2 canais,
  mesma frequência de amostragem na entrada e saída.

## Testes locais

Num Mac ou Linux com compilador C/C++:

```sh
bash scripts/test_dsp.sh
```

Também está incluído um projeto CMake para o mesmo teste.

## Código e licenças

Consulta `PROVENANCE.md`. São preservados os avisos de copyright dos ficheiros
originais e incluídas as licenças GPL-3.0, LGPL-3.0 e a licença MIT do filtro
Kalman. A adaptação é distribuída com código-fonte sob GPL-3.0.
