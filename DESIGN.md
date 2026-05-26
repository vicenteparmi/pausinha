# Design Specification Document: Pausinha

## 1. Conceito Visual e Identidade
O design do **Pausinha** é moderno, lúdico e altamente integrado aos padrões visuais e ergonômicos da Apple (Human Interface Guidelines - HIG). A identidade visual transmite relaxamento, conexão e descontração, essenciais para o contexto de "pausas".

### 1.1. Estética e Atmosfera (Look & Feel)
- **Estilo:** Moderno, limpo, uso extensivo de espaços em branco (White Space), cantos arredondados contínuos e elementos com desfoque de fundo (Glassmorphism).
- **Linguagem Visual:** Foco em avatares (Memojis 3D) para representação dos usuários, trazendo um toque pessoal e nativo do ecossistema Apple.
- **Elementos Gráficos 3D:** Uso de formas 3D flutuantes (estrelas pontiagudas, balões de fala, caixas de presentes, confetes) e gradientes suaves no fundo. Os fundos (backgrounds) apresentam interseções abstratas de linhas finas com malhas de cores pastéis.

## 2. Paleta de Cores (Color Tokens)
O app deve suportar nativamente Light e Dark mode, mas o design atual foca intensamente na leveza do Light Mode.
- **Brand Primary:** Laranja Vibrante (`#FF6600` ou similar). 
  - Usos: Logotipo principal (símbolo de pause arredondado), Floating Action Buttons (FAB), bolinhas de status ativo e backgrounds de tags de tempo (ex: "12:24").
- **Backgrounds:**
  - Telas de conteúdo (Home, Listas): Branco puro (`#FFFFFF`).
  - Telas de Onboarding / Modais: Fundos mesclados com gradientes pastéis translúcidos (Rosa Bebê, Pêssego e Lilás Claro).
- **Texto (Typography Colors):**
  - Text Primary: Preto (`#000000`) para máxima legibilidade nos títulos.
  - Text Secondary: Cinza Médio (`#8E8E93`) para descrições, roles/funções na comunidade e marcações de tempo.
- **Superfícies (Cards & Pills):**
  - Cards de "Em pausinha": Branco com `box-shadow` muito difusa e opacidade baixa (ex: `rgba(0,0,0,0.05)` com blur grande).
  - Grupos Inativos ("Últimas pausinhas"): Toda a célula de interface passa para um tom acinzentado (Grayscale), com opacidade da view inteira em ~60%.

## 3. Tipografia e Escalas (Typography)
O aplicativo usa exclusivamente a família tipográfica nativa da Apple, com suporte a **Dynamic Type** para acessibilidade.
- **Font Family:** San Francisco (SF Pro Rounded para um visual mais amigável, ou SF Pro Display/Text).
- **Escala Sugerida:**
  - **Large Title:** SF Pro, Heavy/Black, 34pt+ (Ex: "Bora entrar pra fazer pausinhas?").
  - **Title 1/2:** SF Pro, Bold, 22pt - 28pt (Ex: "Criar pausinha", "Comunidade", "Em pausinha").
  - **Body / Callout:** SF Pro, Regular/Medium, 16pt - 17pt (Ex: Nomes dos usuários, botões principais).
  - **Footnote / Caption:** SF Pro, Regular, 12pt - 13pt (Ex: "5 pessoas", tempo do card).

## 4. Componentes de Interface (UI Components)

### 4.1. Botões
- **Primary Auth Button:** Botão padrão da Apple "Sign up with Apple". Preto sólido, ícone da maçã branco, texto centralizado, cantos arredondados (Capsule Shape).
- **FAB (Floating Action Buttons):** 
  - Tamanho: ~50x50pt.
  - Estilo: Círculo perfeito, fundo Laranja Brand, ícones brancos em negrito (SF Symbols: `play.fill` e `plus`).
- **Close Buttons:** Círculos pequenos (~30x30pt) em tom de cinza claro (`#E5E5EA`) com ícone "X" escuro (`xmark`), localizados no canto superior esquerdo dos modais.

### 4.2. Cards e Avatares
- **Pausinha Card (Home):**
  - Elemento horizontal ocupando quase a largura da tela.
  - **Avatares Stacked:** Se houver mais de um participante, os Memojis se sobrepõem com uma borda branca (`stroke` de 2-3pt) para criar a separação. Se houver muitos membros, usar um contador (ex: `+3` em um círculo cinza claro).
  - **Tag de Tempo:** Pill laranja no canto inferior direito com o tempo estipulado.
- **Aura de Comunidade:** Na aba Comunidade, os Avatares possuem um círculo de fundo colorido (amarelo, verde pastel, etc) de forma aleatória ou baseada no ID do usuário, para dar destaque. Abaixo do avatar fica o nome do usuário em peso Bold.

### 4.3. Modais e Bottom Sheets (.sheet)
- Uso pesado da API de folhas do iOS (`presentationDetents: [.medium, .large]`).
- O fundo do Sheet usa o material nativo (`.ultraThinMaterial` ou `.regularMaterial`) para desfocar a tela principal.
- No modal de convite/detalhes, um Memoji gigante com animação de entrada fica centralizado no topo.

- Uso de Custom Navigation Bars, preferencialmente utilizando os títulos grandes nativos (Large Titles) nas listas para manter a consistência com o iOS.

## 5. Experiência do Usuário (UX) e Animações
- **Micro-interações:** Respostas táteis (Haptic Feedback) obrigatórias usando `UIImpactFeedbackGenerator` (.light para cliques em botões, .success ao criar uma pausa).
- **Live Activities (ActivityKit):** 
  - **Lock Screen:** O Card da Live Activity deve ter fundo escuro translúcido com o logo da pausinha e um progress bar ou cronômetro em laranja.
  - **Dynamic Island:** 
    - *Compact:* Ícone de pausa laranja do lado esquerdo, e um timer `12:34` do lado direito.
    - *Expanded:* Exibe o título do grupo e os avatares empilhados.

## 6. Acessibilidade (A11y)
- **VoiceOver:** Todos os Memojis devem ter labels ("Avatar de [Nome]"). Os cards de pausinha devem ler todo o contexto de uma vez: "Pausinha do grupo X, com 5 pessoas. Tempo restante: 15 minutos".
- **Dynamic Type:** Textos e cards devem escalar corretamente se o usuário aumentar o tamanho da fonte no sistema iOS.
