# Auditoria de Estoque

Aplicativo Flutter para contagem e conferência de estoque em campo. O app trabalha offline, usa uma base local de produtos e gera relatórios de divergência entre o estoque esperado e a quantidade contada.

## Escopo

O projeto cobre o fluxo básico de auditoria:

- importação da base de produtos do cliente;
- contagem por código digitado ou lido pela câmera;
- tratamento de etiquetas de balança;
- revisão de divergências;
- registro de checklist, observações e fotos;
- histórico das auditorias concluídas;
- exportação do relatório em CSV, TXT ou XLSX.

Os dados ficam armazenados localmente em SQLite.

## Importação da Base de Produtos

A importação é feita pela aba `Ajustes`. Os formatos aceitos são:

- `.csv`
- `.txt`
- `.xlsx`

Para arquivos texto, o delimitador é detectado automaticamente entre vírgula, ponto e vírgula e tabulação.

### Layout Esperado

| Posição | Campo | Obrigatório | Observação |
| --- | --- | --- | --- |
| 1 | Código de barras | Sim | Chave principal do produto |
| 2 | Código interno | Não | Usado também para etiquetas de balança |
| 3 | Nome | Sim | Nome exibido na contagem e nos relatórios |
| 4 | Quantidade esperada | Não | Aceita decimal com vírgula ou ponto |

Exemplo:

```csv
codigo_barras;codigo_interno;nome;quantidade_esperada
7891234567890;12345;Arroz Tipo 1;10,5
7899876543210;67890;Feijao Carioca;24
```

Arquivos com ou sem cabeçalho são aceitos. Linhas sem código de barras ou sem nome são ignoradas. Quando um produto já existe, o registro é atualizado pelo código de barras.

## Contagem

A contagem é feita na aba `Contagem`.

Ao ler ou digitar um código, o app apenas localiza o produto e preenche o formulário. A quantidade não é lançada automaticamente. O operador deve informar a quantidade no campo `QTD` e confirmar em `Adicionar`.

Se o produto não existir na base, o app abre um cadastro rápido. Após salvar, a quantidade informada no campo `QTD` é preservada para lançamento.

## Etiquetas de Balança

O app reconhece códigos EAN-13 com prefixos `20` a `29`.

Formato usado na leitura:

```text
PP CCCCC QQQQQ D
```

| Trecho | Descrição |
| --- | --- |
| `PP` | Prefixo da balança |
| `CCCCC` | Código interno do produto |
| `QQQQQ` | Peso em gramas |
| `D` | Dígito final |

Exemplo: `2012345007508`

Interpretação:

- código interno: `12345`
- quantidade: `0.750`

## Auditoria e Exportação

Ao finalizar uma contagem, o app monta um relatório com:

- produtos cadastrados na base;
- itens contados que não estavam vinculados à base;
- quantidade esperada;
- quantidade contada;
- diferença;
- status.

Antes da exportação, é possível preencher checklist, observações e anexar fotos. A contagem é salva no histórico após a exportação ser concluída com sucesso.

Auditorias já fechadas podem ser abertas pelo histórico e exportadas novamente sem gerar uma nova contagem.

## Relatório

Campos exportados:

| Campo | Origem |
| --- | --- |
| Código | Código de barras do produto ou código informado na contagem |
| Nome | Nome cadastrado ou `Desconhecido` |
| Esperado | Quantidade esperada na base |
| Contado | Quantidade lançada na sessão |
| Diferença | `contado - esperado` |
| Status | `Conferido` ou `Pendente` |

Formatos disponíveis:

- CSV
- TXT com delimitador `;`
- XLSX

## Estrutura do Projeto

```text
lib/
  main.dart
  model/
  pages/
  repostiories/
  service/
test/
```

Principais dependências:

- `provider`
- `sqflite`
- `barcode_scan2`
- `file_picker`
- `excel`
- `csv`
- `image_picker`
- `share_plus`

## Desenvolvimento

Instalar dependências:

```bash
flutter pub get
```

Executar análise estática:

```bash
flutter analyze
```

Executar testes:

```bash
flutter test
```

Executar no dispositivo ou emulador:

```bash
flutter run
```

## Observações

- O app foi desenhado para operação offline.
- A base local usa SQLite.
- O caminho `lib/repostiories` contém um erro de grafia mantido por enquanto para evitar uma renomeação ampla dos imports.
- O schema atual do banco está na versão `2`.
