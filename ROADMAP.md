# Roadmap e Plano de Desenvolvimento: Pausinha

Este documento estabelece a priorização das funcionalidades (features) e a ordem cronológica de desenvolvimento do aplicativo **Pausinha**. O objetivo é entregar valor o mais rápido possível, construindo a base do app antes de adicionar integrações avançadas.

## Matriz de Priorização (Impacto vs Esforço)

| Feature | Impacto no Usuário | Esforço Técnico | Prioridade |
| :--- | :---: | :---: | :---: |
| Autenticação (Sign in with Apple) | Alto | Baixo | P1 (Crítico) |
| Criação de Perfil (Nome + Avatar) | Alto | Baixo | P1 (Crítico) |
| Criar e Fechar Pausinhas | Alto | Médio | P1 (Crítico) |
| Feed de Pausinhas Ativas (Tempo Real) | Alto | Alto | P1 (Crítico) |
| Entrar/Sair de Pausinhas | Alto | Médio | P1 (Crítico) |
| Histórico ("Últimas Pausinhas") | Médio | Baixo | P2 (Importante) |
| Live Activities & Dynamic Island | Alto | Alto | P2 (Importante) |
| Aba "Comunidade" (Listagem de Usuários)| Baixo | Baixo | P3 (Desejável) |
| Convites Diretos & Notificações Push | Alto | Alto | P3 (Desejável) |
| Onboarding com Animações 3D | Médio | Médio | P4 (Polimento) |

---

## Ordem de Desenvolvimento (Fases)

Abaixo está a ordem sugerida de desenvolvimento. Não avançaremos para a próxima fase até que a atual esteja completamente funcional e testada.

### Fase 1: Fundação e MVP (Minimum Viable Product)
*Foco: Fazer o app básico funcionar de ponta a ponta.*
1. **Setup do Projeto:** Criação do projeto no Xcode (SwiftUI) e configuração do Backend (Firebase/CloudKit).
2. **Autenticação Básica:** Implementar o "Sign in with Apple" sem interface gráfica complexa, apenas para gerar os tokens.
3. **Criação de Perfil:** Tela simples para definir Nome e fazer o upload do Avatar/Memoji.
4. **Modelagem de Dados:** Estruturar as coleções `Users` e `Pausinhas` no banco de dados.

### Fase 2: O Core do "Pausinha"
*Foco: Permitir que os usuários criem, visualizem e entrem em grupos.*
1. **UI Principal (Home):** Desenvolver a lista "Em pausinha" escutando mudanças em tempo real do banco de dados.
2. **Criar Pausinha (Sheet):** Implementar o modal com o campo de "Título" e "Duração", salvando no banco de dados.
3. **Entrar na Pausinha (Sheet):** Interface detalhada da sala da pausinha, exibindo os avatares empilhados.
4. **Lógica de Salas:** 
   - Usuário entra na sala -> Atualiza o array de `participants` no banco de dados.
   - Usuário sai da sala -> Remove do array.
   - Se o array ficar vazio ou o tempo exceder 15min do estipulado -> Mudar status para "encerrado".
5. **Histórico:** Implementar a visualização das "Últimas Pausinhas" no fim da lista (tons de cinza).

### Fase 3: Integração com Ecossistema Apple
*Foco: Retenção e experiência "Mágica" do iOS.*
1. **Live Activities Setup:** Configurar o ActivityKit no projeto.
2. **UI da Dynamic Island & Lock Screen:** Desenhar os modos Compact, Minimal e Expanded contendo o timer e os avatares.
3. **Ciclo de Vida da Live Activity:** Iniciar a atividade quando o usuário entra em uma sala, atualizar se alguém mais entrar/sair, e encerrar a atividade quando o tempo limite da sala estourar ou a sala fechar.

### Fase 4: Comunidade e Notificações
*Foco: Escalabilidade e engajamento social.*
1. **Aba Comunidade:** Criar a tela listando todos os membros da organização usando um Navigation Bar com Large Title.
2. **Serviço de Push Notifications:** Configurar certificados da Apple (APNs) e conectar ao Backend.
3. **Convites:** Permitir clicar em um usuário da comunidade (ou dentro da sala) para disparar um convite via Push.
4. **Preferências:** Adicionar o botão "Notificar-me de todas as pausinhas".

### Fase 5: Polimento Visual (Design Final)
*Foco: Deixar o app "Premium".*
1. **Refinamento de UI:** Aplicar as cores exatas (`#FF6600`), efeitos de Glassmorphism nos modais e espaçamentos (HIG).
2. **Onboarding Completo:** Implementar as telas explicativas iniciais com os elementos 3D flutuantes.
3. **Micro-interações:** Adicionar Haptic Feedback nos botões e animações suaves (Spring animations) ao abrir modais.
