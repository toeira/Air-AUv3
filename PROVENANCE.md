# Proveniência

## BlueLab

Fonte: https://github.com/erroreyes/bluelab-plugins
Commit: ea8ae932880e0263e2ee95a219bd42ae55f9709e
Versão do plugin de referência: 6.2.4.
Autor original: Nicolas Dittlo / BlueLab.

Foram extraídos os componentes de DSP necessários a `AirProcess3`,
`PartialTracker5`, `FftProcessObj16` e `CrossoverSplitterNBands4`,
com as suas dependências de utilitários, escalas, filtros e DCT.
A implementação da UI/host iPlug2 foi substituída por uma extensão
AUAudioUnit em Objective-C++, interface UIKit/Swift e app de instalação.

Alterações de portabilidade nas fontes extraídas:

- Includes relativos de WDL ajustados à estrutura da pasta.
- Includes gráficos e referências a logging de ficheiros de diagnóstico
  removidos quando não utilizados pelo processamento.
- Include desktop `Utils.h` removido de `CFxRbjFilter.h`.
- `FastMath.cpp` substituído por funções de `<cmath>` para dispensar fastapprox.
  O plugin de referência não ativa FastMath no seu código de inicialização.
- Adaptador mínimo `IPlug_include_in_plug_hdr.h` com tipos de buffer WDL e
  includes padrão, sem código do host iPlug2.
- Definição do formato FFT de 64 bits, igual ao modo double do plugin original.

## WDL

Fonte dos headers e FFT:
https://github.com/iPlug2/iPlug2
Commit: d54f69050f517e43b941d88c2a170f0a840b9ee4.
Os avisos de licença Cockos são mantidos nos ficheiros.

Foi acrescentado e identificado em `fastqueue.h` um adaptador
`WDL_TypedFastQueue` para substituir a API da antiga fork BlueLab,
baseado na fila original e em unidades de amostras.

## Outras dependências incluídas

- SimpleKalmanFilter, Denys Sene: licença MIT incluída.
- DCT Lee: copyright e licença preservados nos headers/fontes originais.
- CFxRbjFilter: versão incluída no repositório BlueLab; fonte preservada
  com a alteração de include identificada acima.

## Adaptação

Código novo em `Sources/App`, `Sources/Extension`, `AirEngine.*`, scripts,
configuração e testes: disponibilizado sob GNU GPL versão 3.
Não é uma publicação oficial da BlueLab.
