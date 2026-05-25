# Auditoria de Estoque

Aplicativo Flutter para contagem, auditoria e conferência de estoque em operação offline. O projeto atende cenários de lojas, mercados, mercearias e equipes que precisam importar uma base atual de produtos, registrar a contagem física e exportar um relatório de divergências.

## Recursos

- Importação de produtos por CSV, TXT ou XLSX.
- Cadastro rápido de produtos não encontrados durante a contagem.
- Leitura de código de barras pela câmera.
- Suporte a códigos de balança EAN-13 com prefixos `20` a `29`.
- Contagem manual com quantidade informada pelo operador.
- Comparação entre quantidade esperada e quantidade contada.
- Checklist de auditoria, observações e anexos de fotos.
- Histórico local de auditorias finalizadas.
- Reexportação de auditorias já concluídas.
- Exportação em CSV, TXT e XLSX.
- Funcionamento offline com persistência local em SQLite.

## Fluxo de Uso

1. Importe o cadastro atual de estoque do cliente em `Ajustes`.
2. Inicie a contagem pela aba `Contagem`.
3. Leia o código pela câmera ou digite o código manualmente.
4. Informe a quantidade contada no campo `QTD`.
5. Toque em `Adicionar` para registrar o item na sessão.
6. Finalize a contagem para revisar divergências.
7. Preencha checklist, observações e fotos, se necessário.
8. Exporte o relatório em CSV, TXT ou XLSX.

## Importação de Produtos

A importação aceita arquivos `.csv`, `.txt` e `.xlsx`. Para CSV e TXT, o delimitador é detectado automaticamente entre vírgula, ponto e vírgula e tabulação.

Colunas esperadas:

| Coluna | Descrição | Obrigatória |
| --- | --- | --- |
| Código de barras | Identificador principal do produto | Sim |
| Código interno | Código interno usado pelo cliente ou balança | Não |
| Nome | Nome do produto | Sim |
| Quantidade esperada | Estoque atual esperado | Não |

Exemplo com ponto e vírgula:

```csv
codigo_barras;codigo_interno;nome;quantidade_esperada
7891234567890;12345;Arroz Tipo 1;10,5
7899876543210;67890;Feijao Carioca;24
```

Observações:

- Arquivos com ou sem cabeçalho são aceitos.
- Quantidades decimais podem usar vírgula ou ponto.
- Produtos existentes são atualizados pelo código de barras.
- Linhas sem código de barras ou sem nome são ignoradas.

## Contagem e Scanner

O scanner não registra quantidade automaticamente. Ao ler um produto, o app prepara o código no formulário. O operador deve conferir ou informar a quantidade e tocar em `Adicionar`.

Esse comportamento evita lançamentos acidentais e permite contagens por caixa, fardo, peso ou qualquer unidade operacional usada pelo cliente.

## Código de Balança

O aplicativo interpreta códigos EAN-13 de balança com prefixos `20` a `29`.

Formato interpretado:

```text
PP CCCCC QQQQQ D
```

- `PP`: prefixo da balança.
- `CCCCC`: código interno do produto.
- `QQQQQ`: peso em gramas, convertido para quilogramas.
- `D`: dígito final do código.

Exemplo:

```text
2012345007508
```

Resultado:

- Prefixo: `20`
- Código interno: `12345`
- Peso: `0.750`

## Auditoria e Histórico

Ao finalizar uma contagem, o aplicativo gera um relatório com todos os produtos importados e os itens contados que não estavam na base original. Cada item recebe quantidade esperada, quantidade contada, diferença e status.

Auditorias finalizadas ficam disponíveis no histórico, com detalhe dos itens, checklist, observações, fotos anexadas e opção de reexportação.

## Exportação

Formatos disponíveis:

- CSV
- TXT com delimitador `;`
- XLSX

Campos exportados:

| Campo | Descrição |
| --- | --- |
| Código | Código de barras usado no relatório |
| Nome | Nome do produto |
| Esperado | Quantidade esperada |
| Contado | Quantidade contada |
| Diferença | Contado menos esperado |
| Status | Conferido ou Pendente |

## Estrutura Técnica

- Flutter
- Provider para estado compartilhado
- SQLite via `sqflite` para persistência local
- `barcode_scan2` para leitura por câmera
- `file_picker` para importação e anexos
- `excel` e `csv` para importação/exportação
- `share_plus` para compartilhamento de relatórios

Principais diretórios:

```text
lib/
  main.dart
  model/
  pages/
  repostiories/
  service/
test/
```

## Executando Localmente

Pré-requisitos:

- Flutter SDK compatível com Dart `>=3.4.0 <4.0.0`.
- Android Studio ou Xcode para execução em emulador/dispositivo.

Instale as dependências:

```bash
flutter pub get
```

Execute os testes:

```bash
flutter test
```

Rode a análise estática:

```bash
flutter analyze
```

Execute no emulador ou dispositivo conectado:

```bash
flutter run
```

## Status

Projeto em desenvolvimento ativo, com foco em uso operacional offline para auditorias de estoque e conferência rápida de divergências.
