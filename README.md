# 📦 Auditoria e Contagem de Estoque

Aplicativo mobile para contagem e auditoria de estoque, com foco em pequenas empresas, mercados e operações que precisam de agilidade e precisão.

---

## 🎯 Objetivo

Facilitar o processo de contagem de estoque, permitindo:

* Importar lista de produtos
* Ler códigos de barras
* Interpretar códigos de balança
* Registrar contagens rapidamente
* Identificar divergências
* Exportar resultados

---

## 👤 Usuários

* Pequenos comerciantes
* Mercados e mercearias
* Estoquistas
* Auditores internos

---

## 📱 Tecnologias

* Flutter
* Armazenamento local (Hive ou SQLite)
* Câmera para leitura de código de barras

---

## 🧩 Funcionalidades

---

### 📥 Importação de Estoque

* Importar produtos via:

  * Excel (.xlsx)
  * CSV / TXT
* Campos:

  * Código de barras
  * Código interno
  * Nome
  * Quantidade esperada (opcional)

---

### 📷 Leitura de Código de Barras

* Uso da câmera do dispositivo
* Leitura automática de:

  * EAN-13
  * EAN-8
  * UPC

#### Comportamento:

* Ao escanear:

  * Produto é localizado automaticamente
  * Campo de contagem é preenchido/incrementado
* Caso produto não exista:

  * Possibilidade de cadastro rápido

---

### ⚖️ Leitura de Código de Balança

Suporte a códigos usados em balanças de mercado (ex: etiquetas de produtos pesáveis).

#### Estrutura comum (exemplo EAN-13):

* Prefixo (geralmente 20–29)
* Código do produto
* Peso ou valor embutido

#### Exemplo:

```
2 12345 000750
```

* 2 → indica balança
* 12345 → código do produto
* 000750 → peso (0.750 kg)

#### Regras:

* Identificar automaticamente códigos de balança
* Extrair:

  * Código do produto
  * Peso ou valor
* Converter peso para quantidade (configurável)

---

### 📦 Contagem de Estoque

* Contagem manual ou via scanner
* Incremento automático ao escanear
* Edição manual de quantidade
* Status:

  * Conferido
  * Pendente

---

### 📋 Auditoria (Opcional)

* Checklist
* Perguntas (Sim / Não / N/A)
* Observações
* Fotos

---

### 🕓 Histórico

* Registro de contagens
* Visualização de detalhes
* Revisão de divergências

---

### 📊 Relatórios

* Diferença entre esperado x contado
* Percentual de divergência
* Lista de inconsistências

---

### 📤 Exportação

* Excel (.xlsx)
* CSV (.txt)

Conteúdo exportado:

* Código
* Nome
* Quantidade esperada
* Quantidade contada
* Diferença

---

## 🔄 Fluxo do Usuário

1. Importa estoque
2. Inicia contagem
3. Escaneia produtos ou insere manualmente
4. Sistema atualiza quantidades automaticamente
5. Finaliza contagem
6. Exporta relatório

---

## 🧠 Regras de Negócio

* Código de barras deve ser único
* Scanner incrementa automaticamente a contagem
* Código de balança deve ser interpretado automaticamente
* Diferença = contado - esperado
* Itens não contados ficam pendentes

---

## 🗄️ Modelos de Dados

### Produto

* id
* codigoBarras
* codigoInterno
* nome
* quantidadeEsperada

---

### Contagem

* id
* data
* status

---

### ItemContagem

* id
* contagemId
* produtoId
* quantidadeContada
* diferenca

---

## 💾 Persistência Local

* Funciona 100% offline
* Dados armazenados localmente
* Preparado para sincronização futura

---

## 📱 Telas

* Importar estoque
* Scanner de código de barras
* Lista de produtos
* Tela de contagem
* Histórico
* Exportação

---

## 🚧 MVP

### Inclui:

* Importação CSV
* Scanner de código de barras
* Suporte a código de balança
* Contagem automática
* Exportação CSV

### Futuro:

* Excel completo
* Backend
* Leitor via hardware externo
* Dashboard web

---

## 🧪 Uso com IA

Exemplos:

* "Crie leitor de código de barras com mobile_scanner no Flutter"
* "Implemente parser de código de balança EAN-13"
* "Crie função para extrair peso de código 2xxxx"
* "Gere tela de scanner integrada com contagem"

---

## ⚙️ Diretrizes

* Simples e rápido
* Foco em uso operacional
* Offline-first
* Baixo consumo de bateria

---

## 💡 Visão

Tornar a contagem de estoque:

* Rápida (via scanner)
* Inteligente (balança automática)
* Acessível (pequenas empresas)

---

## 📌 Status

🚧 MVP em desenvolvimento com foco em leitura de código de barras e contagem inteligente
