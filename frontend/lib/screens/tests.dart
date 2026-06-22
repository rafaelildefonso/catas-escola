import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/ai_components/component_factory.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final List<Map<String, dynamic>> _testComponents = [
    {
      'type': 'action_approval',
      'data': {
        'title': 'Enviar Relatório Mensal',
        'description':
            'Deseja enviar o relatório consolidado para a diretoria agora?',
        'danger_level': 'low',
      },
    },
    {
      'type': 'action_approval',
      'data': {
        'title': 'Excluir Backup Antigo',
        'description':
            'Esta ação é irreversível. O backup de Janeiro será removido permanentemente.',
        'danger_level': 'high',
      },
    },
    {
      'type': 'contact_select',
      'data': {
        'purpose': 'Selecione os destinatários do convite:',
        'multi_select': true,
      },
    },
    {
      'type': 'preview_whatsapp',
      'data': {
        'recipient_name': 'João Silva',
        'message_text':
            'Olá João! Confirmamos sua reunião de amanhã às 14h. Até lá!',
        'timestamp': '10:45',
      },
    },
    {
      'type': 'preview_email_draft',
      'data': {
        'to': ['contato@empresa.com', 'suporte@empresa.com'],
        'subject': 'Proposta de Parceria CATAS',
        'body_preview':
            'Olá, tudo bem?\n\nGostaríamos de apresentar o CATAS, nosso sistema de automação assistida por IA. Acreditamos que seu time pode se beneficiar muito...',
      },
    },
    {
      'type': 'preview_calendar_event',
      'data': {
        'title': 'Reunião de Alinhamento - Projeto SaaS',
        'date': 'Amanhã, 15 de Março',
        'time': '14:00 - 15:00',
        'attendees': ['ana@catas.ai', 'bruno@catas.ai', 'carlos@catas.ai'],
        'meet_link': 'https://meet.google.com/abc-defg-hij',
      },
    },
    {
      'type': 'preview_docs',
      'data': {
        'title': 'Especificação Técnica - Backend Python',
        'snippet':
            'O backend utiliza FastAPI para prover endpoints de chat e integração com o Gemini...',
        'url': 'https://docs.google.com/document/d/123456789',
      },
    },
    {
      'type': 'drive_file_select',
      'data': {
        'purpose': 'Anexar documentos ao processo:',
        'multi_select': true,
      },
    },
    {
      'type': 'sheets_table_preview',
      'data': {
        'title': 'Resultados Trimestrais',
        'headers': ['Mês', 'Vendas', 'Crescimento'],
        'rows': [
          ['Janeiro', 'R\$ 15.000', '+10%'],
          ['Fevereiro', 'R\$ 18.500', '+23%'],
          ['Março', 'R\$ 22.000', '+19%'],
        ],
      },
    },
    {
      'type': 'multiple_choice',
      'data': {
        'question': 'Como você deseja prosseguir com o pagamento?',
        'options': [
          {'id': '1', 'label': 'Cartão de Crédito'},
          {'id': '2', 'label': 'Pix (Desconto 5%)'},
          {'id': '3', 'label': 'Boleto Bancário'},
        ],
      },
    },
  ];

  void _handleResponse(String type, Map<String, dynamic> response) {
    debugPrint('Componente: $type');
    debugPrint('Resposta: $response');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Interação em $type: ${response.toString()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Galeria de Componentes de IA',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estes componentes são gerados dinamicamente pela IA para interagir com o usuário ou mostrar prévias de ações.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            AIComponentFactory(
              components: _testComponents,
              onComponentResponse: _handleResponse,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
