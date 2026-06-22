import '../components/brand_logo.dart';

class SuggestedPrompt {
  final String category;
  final String prompt;
  final List<LogoId> logos;

  const SuggestedPrompt({
    required this.category,
    required this.prompt,
    required this.logos,
  });
}

class SuggestedPromptsData {
  static const List<String> categories = [
    'Todos',
    'Produtividade',
    'Vendas',
    'Marketing',
    'Pessoal',
    'Financeiro',
  ];

  static const List<SuggestedPrompt> prompts = [
    // Produtividade
    SuggestedPrompt(
      category: 'Produtividade',
      prompt: 'Agendar reunião com meu time amanhã às 9h',
      logos: [LogoId.googleCalendar, LogoId.googleMeet],
    ),
    SuggestedPrompt(
      category: 'Produtividade',
      prompt: 'Resumir meus e-mails recebidos hoje',
      logos: [LogoId.googleGmail],
    ),
    SuggestedPrompt(
      category: 'Produtividade',
      prompt: 'Criar tarefa: Revisar documento do projeto',
      logos: [LogoId.notion],
    ),
    SuggestedPrompt(
      category: 'Produtividade',
      prompt: 'Me lembre de beber água a cada 2 horas hoje',
      logos: [LogoId.whatsapp],
    ),

    // Vendas
    SuggestedPrompt(
      category: 'Vendas',
      prompt: 'Enviar mensagem de follow-up para o cliente João',
      logos: [LogoId.whatsapp],
    ),
    SuggestedPrompt(
      category: 'Vendas',
      prompt: 'Registrar nova oportunidade de venda no Notion',
      logos: [LogoId.notion],
    ),
    SuggestedPrompt(
      category: 'Vendas',
      prompt: 'Avisar o time no Slack sobre o fechamento de um negócio',
      logos: [LogoId.slack],
    ),
    
    // Marketing
    SuggestedPrompt(
      category: 'Marketing',
      prompt: 'Adicionar leads de uma campanha a uma planilha',
      logos: [LogoId.googleSheets],
    ),
    SuggestedPrompt(
      category: 'Marketing',
      prompt: 'Rascunhar um e-mail marketing para anunciar a nova funcionalidade',
      logos: [LogoId.googleGmail],
    ),

    // Pessoal
    SuggestedPrompt(
      category: 'Pessoal',
      prompt: 'Agendar horário no dentista para a próxima terça à tarde',
      logos: [LogoId.googleCalendar],
    ),
    SuggestedPrompt(
      category: 'Pessoal',
      prompt: 'Criar uma lista de compras para a semana',
      logos: [LogoId.notion],
    ),

    // Financeiro
    SuggestedPrompt(
      category: 'Financeiro',
      prompt: 'Extrair valores da última nota fiscal recebida por email',
      logos: [LogoId.googleGmail],
    ),
    SuggestedPrompt(
      category: 'Financeiro',
      prompt: 'Adicionar o gasto de R\$ 50 com Uber na planilha de despesas',
      logos: [LogoId.google],
    ),
  ];
}
