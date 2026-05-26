# Changelog de Desenvolvimento — Pausinha

Este arquivo registra cronologicamente o progresso de implementação, decisões técnicas e de produto tomadas durante o desenvolvimento do app.

---

## Fase 1 — Fundação e MVP

**Data:** 18/05/2026  
**Status:** ✅ Concluída

### O que foi implementado

| Arquivo | Tipo | Descrição |
|---|---|---|
| `DataModels/PausinhaGroup.swift` | Novo | Modelo de dados do grupo de pausa |
| `Services/PausinhaService.swift` | Novo | Serviço CloudKit banco público |
| `PausinhaApp.swift` | Modificado | Schema atualizado + injeção do serviço |

### Decisões técnicas

**CloudKit: banco público para Pausinhas**  
O `CloudKitService` existente usa `privateCloudDatabase` (dados pessoais do usuário). Para que todos os membros da organização vejam os grupos em tempo real, o modelo `PausinhaGroup` é persistido no `publicCloudDatabase` através de um serviço dedicado — `PausinhaService`. A separação garante responsabilidades bem definidas e facilita testes independentes.

**Serialização de `participantIDs`**  
SwiftData não suporta nativamente arrays de tipos primitivos em todos os cenários de sincronização. A solução adotada é serializar `participantIDs: [String]` como JSON interno (`participantIDsJSON: String`) com computed properties que fazem o encode/decode transparentemente.

**Avatar via `Data`**  
O campo `profileImageData: Data` no `UserProfile` suporta qualquer imagem — foto da galeria, câmera ou Memoji exportado como `UIImage → Data`. Não é necessário um tratamento especial para Memoji nesta fase.

### Decisões de produto

- **Fluxo de onboarding adiado:** O roteamento condicional (Login → Setup → Home) foi adiado para evitar bloquear o core do app. Usuários que abrem o app vão direto para a Home por enquanto.
- **profileType fora do onboarding pessoal:** A categoria (Bondiano, Boatardiano, Mentoria) pertence ao contexto da organização e deve ser configurada em um setup de organização futuro.
- **Grace period de 15 minutos:** Um grupo continua aberto por até 15 minutos após o tempo estipulado (`expiresAt`). Isso permite que conversas naturalmente se estendam sem encerrar abruptamente. Após esse período, o grupo é fechado automaticamente.
- **Histórico de 3 horas:** Grupos encerrados ficam visíveis no histórico por 3 horas, permitindo que usuários que perderam a pausa saibam o que aconteceu recentemente.
- **Encerramento automático por grupo vazio:** Se todos os participantes saírem, o grupo é encerrado imediatamente (não espera o grace period).

---

## Fase 2 — Core do "Pausinha"

**Data:** 18/05/2026  
**Status:** ✅ Concluída

### O que foi implementado

| Arquivo | Tipo | Descrição |
|---|---|---|
| `Views/Home/HomeView.swift` | Modificado | Conectado ao `PausinhaService` com dados reais |
| `Views/Home/Components/PausinhaCardView.swift` | Novo | Card de pausinha ativa |
| `Views/Home/Components/PausinhaCardClosedView.swift` | Novo | Card de pausinha encerrada (histórico) |
| `Views/Home/Components/StackedAvatarsView.swift` | Novo | Avatares empilhados com borda branca |
| `Views/Pausinha/CreateNew/CreateNewPausinhaView.swift` | Modificado | Modal funcional com título e duração |
| `Views/Pausinha/PausinhaDetailSheet.swift` | Novo | Sheet de detalhes com entrar/sair |

### Decisões técnicas

**`@Environment(PausinhaService.self)` nas views**  
Todas as views da Fase 2 consomem o `PausinhaService` via environment, evitando prop drilling. O serviço é `@Observable`, então mudanças em `activePausinhas` propagam automaticamente para as views.

**Fetch no `onAppear` da HomeView**  
A lista é carregada no `onAppear` da HomeView com `Task { await pausinhaService.fetchPausinhas() }`. Na Fase 3, isso será substituído por assinaturas em tempo real via `CKQuerySubscription` (já preparado no `PausinhaService.setupRealtimeSubscription()`).

**Duração pré-definida (Picker)**  
O modal de criação oferece durações fixas (5, 10, 15, 30, 60 minutos) em vez de um input livre. Isso reduz fricção e evita criação de grupos com durações inválidas.

**Avatares como iniciais (fallback)**  
Quando um participante não tem imagem de perfil, o `StackedAvatarsView` exibe um círculo colorido com a inicial do nome. A cor é determinada deterministicamente pelo hash do `userID`, garantindo consistência entre sessões.

**Um usuário por pausa**  
Ao entrar em uma nova pausinha, o app verifica se o usuário já está em outra e o remove automaticamente antes de adicionar na nova. Regra do PRD: "um usuário só pode estar em uma pausinha ativa por vez."

### Decisões de produto

- **Criador entra automaticamente:** Ao criar uma pausinha, o `creatorID` é adicionado automaticamente ao array `participantIDs`. Isso reflete a intenção natural — quem cria a pausa está participando dela.
- **Criador não pode sair sem fechar:** O criador pode encerrar a sala ou transferi-la (Fase 4), mas não pode simplesmente "sair" deixando a sala sem dono. Ao tentar sair, é apresentada opção de encerrar.
- **Títulos sugeridos:** O modal de criação oferece sugestões de título (chips) como "Café ☕", "Almoço 🍕", "Uno 🃏" para reduzir fricção de digitação.
- **Tag de tempo restante:** Os cards ativos exibem o tempo restante em vez do tempo total, pois é a informação mais relevante para quem está decidindo entrar.

### Atualização pós-Fase 2 — Input livre de duração e horário fixo

| Arquivo | Tipo | Descrição |
|---|---|---|
| `Views/Pausinha/CreateNew/CreateNewPausinhaView.swift` | Modificado | Refatorado em coordinator pequeno |
| `Views/Pausinha/CreateNew/TimeMode.swift` | Novo | Enum `TimeMode` compartilhado |
| `Views/Pausinha/CreateNew/TitleInputSection.swift` | Novo | Campo de título + chips isolados |
| `Views/Pausinha/CreateNew/DurationInputSection.swift` | Novo | Container do segmented control de tempo |
| `Views/Pausinha/CreateNew/DurationPresetsGrid.swift` | Novo | Grid de presets (5, 10, 15, 30, 60 min) |
| `Views/Pausinha/CreateNew/DurationStepper.swift` | Novo | Stepper livre (1–480 min) |
| `Views/Pausinha/CreateNew/EndTimePicker.swift` | Novo | Picker de horário fixo de encerramento |

**Decisões de produto:**
- **Modo "Duração":** presets rápidos + stepper livre. O stepper desmarca o preset e permite qualquer valor de 1 a 480 minutos.
- **Modo "Horário":** `DatePicker` de hora/minuto. Se o horário já passou, a pausinha é agendada para o dia seguinte com aviso visual.
- **Padrão de arquitetura:** A partir daqui, cada subview extraída em arquivo próprio para manter arquivos pequenos e focados.

---

## Fase 3 — Live Activities & Dynamic Island

**Data:** 18/05/2026  
**Status:** ✅ Concluída (Requer configuração de Target no Xcode pelo usuário)

### O que foi implementado

| Arquivo | Tipo | Descrição |
|---|---|---|
| `Info.plist` | Modificado | Adicionado suporte a Live Activities (`NSSupportsLiveActivities`). |
| `DataModels/PausinhaAttributes.swift` | Novo | Estrutura compartilhada definindo estado estático e dinâmico da Atividade. |
| `Services/LiveActivityManager.swift` | Novo | Envolve as chamadas do ActivityKit (`request`, `update`, `end`). |
| `PausinhaWidget/PausinhaWidgetLiveActivity.swift` | Novo | A UI da Dynamic Island e Lock Screen. |
| `Services/PausinhaService.swift` | Modificado | Adicionado ganchos para o `LiveActivityManager` nos fluxos de vida da pausinha. |

### Decisões técnicas

**Gerenciamento Local (Local Update)**  
Para manter a simplicidade e rapidez da entrega de valor, optamos por atualizar as atividades através do `LiveActivityManager` injetado diretamente no `PausinhaService` local, ao invés de configurar atualizações remotas via APNs (Fase 4). Isso significa que as atualizações só disparam quando o aplicativo está ativo, porém o relógio contínuo (timer na lock screen) rodará normalmente baseando-se no parâmetro estático `expiresAt`.

**Configuração Manual no Xcode**  
A extensão do Widget foi criada programaticamente, mas requer que o usuário configure o Target via Xcode (File > New > Target... > Widget Extension) para garantir que o build do app seja mantido íntegro e assinado.
