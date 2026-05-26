# Product Requirements Document (PRD): Pausinha

## 1. Visão Geral (Overview)
**Pausinha** é um aplicativo nativo para iOS focado em organizar, sincronizar e promover momentos de pausa e descompressão entre membros de uma mesma organização, comunidade ou time (ex: "academers"). Ele funciona como um "hub de status" temporário onde os usuários podem ver quem está disponível para interagir, criar grupos de pausa, e convidar colegas. 

O diferencial do app é a sua profunda integração com o ecossistema Apple, focando em interações rápidas e visibilidade passiva através de **Live Activities** e **Dynamic Island**.

## 2. Público-Alvo e Personas
- **O Focado (Estudante/Desenvolvedor):** Passa horas codando ou estudando e esquece de fazer pausas. Precisa de um lembrete amigável e de ver que seus amigos estão pausando para se sentir encorajado a parar.
- **O Socializador:** Gosta de juntar pessoas para tomar um café ou jogar algo rápido. Usa o app para "chamar a galera" sem precisar mandar mensagens individuais em grupos do WhatsApp/Slack.

## 3. Histórias de Usuário (User Stories) e Casos de Uso

### 3.1. Onboarding e Autenticação
- **Como um novo usuário**, eu quero me cadastrar usando o "Sign in with Apple" para não precisar criar e memorizar mais uma senha.
- **Como um novo usuário**, eu quero configurar meu perfil com meu nome e meu Avatar (que pode ser gerado nativamente via API da Apple como Memoji, ou carregando uma foto/emoji), para que os outros me reconheçam facilmente.

### 3.2. Gerenciamento de Pausinhas (Grupos)
- **Como um usuário**, eu quero criar uma pausinha definindo um título (ex: "Café na copa", "Bora jogar Uno") e um horário limite, para que as pessoas saibam o propósito e a duração do break.
- **Como um usuário**, eu quero ver uma lista em tempo real de todas as pausinhas ativas na minha organização, para decidir se me junto a alguma ou crio a minha.
- **Como um participante**, eu quero poder convidar usuários específicos da organização para a minha pausinha, enviando uma notificação direta a eles.
- **Como um usuário**, eu quero ver um histórico das "Últimas pausinhas" (grupos recém-encerrados) para saber quem estava disponível recentemente, caso eu tenha perdido a oportunidade.

### 3.3. Interação e Comunidade
- **Como um usuário**, eu quero acessar a aba "Comunidade" para encontrar rapidamente meus amigos e pessoas da minha organização.
- **Como um usuário**, eu quero ver o status das pessoas na comunidade (se elas estão em alguma pausinha agora ou disponíveis).

### 3.4. Integração Apple (Live Activities)
- **Como um participante ativo**, eu quero que o status da minha pausinha atual apareça na minha Dynamic Island e Lock Screen (Live Activity), para que eu saiba quanto tempo de pausa me resta sem precisar abrir o aplicativo.
- **Como um usuário**, eu quero receber notificações push apenas quando for convidado para uma pausinha, mas quero ter a opção de ativar notificações para ser avisado de **todas** as pausinhas criadas na organização.

## 4. Regras de Negócio e Casos Extremos (Edge Cases)
1. **Encerramento Automático / Manual:** A sala só é fechada automaticamente quando o último participante sai dela, OU quando o tempo ultrapassar 15 minutos além do fim estimado. O criador da pausinha também tem a permissão de encerrar a sala manualmente a qualquer momento.
2. **Fim do Tempo:** Quando o tempo da duração estipulada expira, os usuários continuam na sala (conforme regra acima), mas a **Live Activity** deve alertar os usuários de forma clara de que o tempo estipulado já acabou.
3. **Visibilidade do Histórico:** Grupos em "Últimas pausinhas" devem desaparecer completamente após um período de *grace period* (ex: 3 horas).
4. **Limites de Participação:** Um usuário só pode estar em **uma** pausinha ativa por vez. Ao tentar entrar em uma nova, ele deve sair automaticamente da anterior.

## 5. Modelagem de Dados (Visão Macro)
- **User:** `id`, `name`, `avatar_data` (Memoji, Emoji ou URL da foto), `current_pausinha_id`, `created_at`, `notify_all` (bool).
- **Pausinha:** `id`, `title`, `creator_id`, `participants` (array de IDs), `expires_at`, `status` (active, closed), `created_at`.

## 6. Métricas de Sucesso (KPIs)
- **DAU/MAU:** Quantidade de usuários que abrem o app diariamente/mensalmente.
- **Pausinhas Criadas por Dia:** Indica o engajamento de criação.
- **Média de Participantes por Pausinha:** Indica a efetividade do app em juntar pessoas.
- **Uso de Live Activities:** Percentual de pausinhas que permanecem ativas na Lock Screen até o fim do tempo.
