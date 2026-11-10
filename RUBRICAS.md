# Roteiro de Apresentação do Projeto

**Tempo total:** até **7 minutos**  
**Importante:** a demonstração deve durar **no máximo 2 minutos** e mostrar pelo menos **quatro funcionalidades principais que não sejam CRUD**.

## 1. Abertura — 20 segundos

Apresentem:

- Nome do projeto e turma
- Integrantes
- Uma frase explicando o que o sistema faz

> “O [nome do sistema] atende [público-alvo] e ajuda a resolver [problema].”

## 2. Projeto, público-alvo e casos de uso — 55 segundos

- Expliquem brevemente o problema e quem usaria o sistema.
- Apresentem **cinco casos de uso principais**, cada um acompanhado da tela correspondente.
- Deixem claro o objetivo de cada caso de uso.

## 3. Modelo de domínio — 35 segundos

Mostrem o diagrama de classes e expliquem:

- As principais classes e seus atributos
- Os relacionamentos entre as classes
- Como o modelo corresponde ao sistema implementado

## 4. Fluxogramas dos casos de uso — 55 segundos

Apresentem:

- Um fluxograma de **recuperação de dados**
- Um fluxograma de **entrada de dados**

Em cada um, expliquem o caminho da requisição pelas camadas, incluindo a participação do **Repository**.

## 5. Arquitetura e organização do código — 1 minuto

Mostrem a arquitetura e os diretórios de **Controllers, Services, Repositories e Models**.

Expliquem um fluxo do sistema:

1. O **Controller** recebe a requisição.
2. O **Service** executa o caso de uso e as regras da aplicação.
3. O **Repository** realiza a operação ou consulta necessária.
4. O **Model** representa os dados envolvidos.
5. A resposta retorna ao frontend pela API.

Mostrem também que o **frontend e a API estão separados** e que o frontend consome a API por requisições. Essa separação pode ser demonstrada mesmo em ambiente local.

## 6. Demonstração funcional — até 2 minutos

Demonstrem **pelo menos quatro funcionalidades principais não CRUD**, de ponta a ponta. Para cada uma, mostrem a ação do usuário e o resultado produzido pelo sistema.

A demonstração pode ser feita por vídeo ou com o sistema em execução. Não contem como funcionalidades exigidas ações isoladas de cadastrar, listar, consultar, editar ou excluir registros.

## 7. Persistência e consultas — 35 segundos

Apresentem evidências de que:

- O sistema usa ORM para operações CRUD.
- As consultas SQL ficam na camada Repository e retornam resultados corretos.

## 8. Tecnologias, README e bônus — 30 segundos

- Citem as tecnologias utilizadas.
- Mostrem o README e a lista dos casos de uso implementados.
- Se aplicável, indiquem os bônus: integração funcional de IA como serviço, frontend e API hospedados, e termos de consentimento com a decisão do usuário registrada.

## 9. Encerramento — 10 segundos

Reforcem em uma frase o problema resolvido e agradeçam.

## Checklist de preparação

- [ ] Slides com descrição, público-alvo e problema
- [ ] Cinco casos de uso principais com suas telas
- [ ] Diagrama de classes coerente com o sistema
- [ ] Fluxogramas de entrada e recuperação de dados, incluindo o Repository
- [ ] Arquitetura e diretórios de Controllers, Services, Repositories e Models
- [ ] Separação entre frontend e API e evidência de consumo por requisições
- [ ] Demonstração de quatro funcionalidades não CRUD em até 2 minutos
- [ ] Evidências de CRUD com ORM e consultas SQL no Repository
- [ ] README com a lista dos casos implementados
- [ ] Apresentação ensaiada e dentro do limite de 7 minutos

**Observação:** a rubrica não exige apresentar uma lista de 20 funcionalidades na apresentação. O README deve listar os casos de uso implementados, e a demonstração deve destacar quatro funcionalidades principais não CRUD.


---

# Roteiro respondido — CATAS

## 1. Abertura — 20 segundos

> “Somos da turma 3A1: Rafael Ildefonso Furtado, Lucas Salman Resende, Henrique Santos Tavares, Miguel Teixeira Valadão e Lucas Nunes Araújo. Nosso projeto é o CATAS, *Context Aware Task Automation System*. Ele atende pessoas e equipes que precisam automatizar tarefas repetitivas e permite criar, executar e acompanhar automações usando linguagem natural.”

---

## 2. Projeto, público-alvo e casos de uso — 55 segundos

### Problema e público-alvo

O CATAS é destinado a pessoas e equipes que realizam tarefas repetitivas e precisam integrá-las a serviços como Gmail, Google Calendar, Drive e Sheets. O problema é que automatizar essas tarefas costuma exigir configuração técnica, conhecimento de APIs e montagem manual de fluxos. No CATAS, a pessoa descreve o resultado desejado em linguagem natural.

### Cinco casos de uso principais

| Caso de uso | Tela correspondente | Objetivo |
|---|---|---|
| Autenticar-se e aceitar os termos | Login e cadastro | Criar uma conta, entrar com segurança e registrar o aceite dos termos. |
| Conversar com a IA | Chat | Enviar um pedido em linguagem natural; a IA responde ou prepara uma automação. |
| Conectar integração externa | Integrações | Conectar Gmail, Calendar, Drive ou Sheets via OAuth. |
| Criar e executar automação | Automações ativas | Criar, executar, pausar, revisar e agendar tarefas. |
| Consultar e exportar resultados | Dashboard e Relatórios | Ver métricas, execuções e exportar dados. |

> “O usuário pode, por exemplo, pedir: ‘Envie um e-mail todos os dias às 9h’. A IA identifica a intenção, coleta os dados necessários, cria o plano e o sistema acompanha sua execução.”

---

## 3. Modelo de domínio — 35 segundos

Apresentar o arquivo `diagrama-de-classes.html`.

> “As classes centrais são `User` e `Profile`: cada usuário possui um perfil com plano, cota e preferências. Um perfil possui sessões de chat, automações, integrações e execuções. Uma sessão de chat contém mensagens. Uma automação armazena o gatilho e os passos do fluxo; cada execução gera uma `AutomationRun`, e cada etapa gera uma `AutomationStepLog`.”

```text
User 1 ── 1 Profile
Profile 1 ── N ChatSession ── N Message
Profile 1 ── N Automation ── N AutomationRun ── N AutomationStepLog
Profile 1 ── N Integration
```

Esses relacionamentos representam o processo implementado: conversar com a IA, criar uma automação, executá-la e manter o histórico e os logs.

---

## 4. Fluxogramas dos casos de uso — 55 segundos

### Recuperação de dados: dashboard

```text
Flutter / Dashboard
        ↓ GET /api/v1/relatorios/dashboard
routes.py
        ↓
RelatorioController
        ↓
GerarEstatisticasDashboardService
        ↓
DashboardRepository
        ↓ SQL / procedure / fallback SQLite
Banco de dados
        ↓
JSON → API → Flutter
```

> “Esse fluxo utiliza o Repository porque o dashboard precisa de consultas agregadas: execuções, taxa de sucesso, duração média, integrações e mensagens.”

### Entrada de dados: feedback de uma resposta da IA

```text
Flutter: like ou dislike
        ↓ POST /api/v1/chat/messages/<id>/feedback
routes.py
        ↓
FeedbackController
        ↓
RegistrarFeedbackService
        ↓
FeedbackRepository verifica registro existente
        ↓
Model MessageFeedback salva um novo registro
ou Repository atualiza/remove o existente
        ↓
Banco → JSON → Flutter
```

### Importante

> “O Controller cuida da requisição HTTP e autenticação, o Service aplica as regras, o Repository executa a consulta específica e o Model representa o dado persistido.”

---

## 5. Arquitetura e organização do código — 1 minuto

```text
Flutter
  ↓ HTTP + JWT
Flask API
  ↓
routes.py → Controller → Service → Model / Repository → Banco
                                  ↓
                            Worker Flask
                                  ↓
                  Gmail, Calendar, Drive e Sheets
```

| Camada | Responsabilidade |
|---|---|
| `controllers/` | Recebem requisições e devolvem respostas HTTP. |
| `services/` | Contêm os casos de uso e as regras de negócio. |
| `repositories/` | Concentram consultas complexas, filtros, JOINs e relatórios. |
| `models/` | Representam as entidades SQLAlchemy e o CRUD básico. |
| `worker/` | Executa automações em segundo plano, sem bloquear a API. |

> “O frontend e a API são separados. O Flutter consome a API Flask por requisições HTTP com JWT; ele não acessa o banco diretamente. Ao receber uma mensagem, a API valida dados, quota, sessão e integrações, processa a intenção com IA e, se houver automação, registra a execução e encaminha o plano ao worker.”

---

## 6. Demonstração funcional — até 2 minutos

Preparar previamente uma conta de demonstração, Gmail conectado, uma automação pronta e ao menos uma execução registrada.

| Tempo | Ação | Resultado demonstrado |
|---|---|---|
| 0:00–0:20 | Enviar no chat um pedido de automação em linguagem natural. | A IA interpreta o pedido e mostra o plano. |
| 0:20–0:40 | Abrir Automações ativas. | Exibir fluxo, status e próxima execução. |
| 0:40–1:00 | Usar “Executar agora”. | Mostrar o e-mail recebido ou a execução concluída. |
| 1:00–1:20 | Abrir detalhe da execução ou notificações. | Exibir status e logs por etapa. |
| 1:20–1:40 | Mostrar o agendamento salvo. | Comprovar que a automação é recorrente. |
| 1:40–2:00 | Abrir Relatórios e exportar CSV, Excel ou PDF. | Mostrar que os dados persistidos viram relatório. |

> “Aqui a IA transforma uma frase em uma automação. O worker executa a ação externa, o sistema registra cada etapa, notifica o resultado e disponibiliza os dados para relatório e exportação.”

As quatro funcionalidades não CRUD mínimas são: interpretação do comando por IA, execução da automação, acompanhamento por logs/notificações e geração/exportação de relatórios.

---

## 7. Persistência e consultas — 35 segundos

> “Usamos SQLAlchemy como ORM. Cada modelo representa uma tabela e possui métodos como `salvar`, `atualizar`, `deletar`, `listar_todos` e `to_dict`.”

Mostrar `backend/models/automation.py` ou `backend/models/message.py` como evidência do ORM.

> “As consultas complexas ficam no Repository. No `dashboard_repository.py`, por exemplo, são calculadas execuções, taxa de sucesso, duração média, status, integrações e mensagens. Em produção, as consultas podem usar procedures do PostgreSQL; no desenvolvimento há fallback compatível com SQLite.”

---

## 8. Tecnologias, README e bônus — 30 segundos

| Área | Tecnologias |
|---|---|
| Frontend | Flutter, Dart, Provider, GoRouter e Dio. |
| API | Python, Flask e SQLAlchemy. |
| Banco | PostgreSQL em produção e SQLite no desenvolvimento. |
| IA | Groq, Gemini e OpenAI. |
| Integrações | Google OAuth, Gmail, Calendar, Drive e Sheets. |
| Serviços extras | Stripe, Firebase, Docker, Pytest e Flutter Test. |

Mostrar o `README.md` e sua lista de funcionalidades/casos de uso.

### Bônus aplicáveis

- IA funcional: a IA classifica a intenção e gera planos de automação.
- Frontend e API hospedados: apresentar apenas se estiverem acessíveis no dia da banca.
- Consentimento: o sistema registra o aceite em `/api/v1/termos/aceite`.

---

## 9. Encerramento — 10 segundos

> “O CATAS reduz a barreira técnica para automação: a pessoa descreve o resultado desejado, e a plataforma executa, acompanha e registra todo o processo. Obrigado.”

---

## Checklist final de apresentação

- [ ] Mostrar `diagrama-de-classes.html`.
- [ ] Mostrar as cinco telas dos casos de uso.
- [ ] Apresentar os dois fluxogramas com participação do Repository.
- [ ] Demonstrar pelo menos quatro funcionalidades não CRUD em até dois minutos.
- [ ] Mostrar um Model SQLAlchemy e um Repository com consulta SQL.
- [ ] Mostrar frontend e API separados, comunicando-se por HTTP.
- [ ] Mostrar o README com a lista de funcionalidades.
- [ ] Não expor `.env`, chaves, tokens, dados pessoais ou dados de pagamento.
- [ ] Ensaiar a apresentação para respeitar o limite de sete minutos.

---

## Informações técnicas verificadas no código

- O worker atual usa **Flask**.
- O backend atual registra **128 rotas** em `backend/routes.py`.
- O diretório `backend/models/` possui **21 modelos SQLAlchemy**.
- Antes da apresentação, alinhar o README com esses números para evitar divergências com o código.
