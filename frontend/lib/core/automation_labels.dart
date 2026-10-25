String friendlyAutomationStepName(String moduleId) {
  const labels = <String, String>{
    'ai.transform_data': 'Organizar informações',
    'flow.wait': 'Aguardar o momento certo',
    'flow.condition': 'Verificar uma condição',
    'flow.loop': 'Repetir ações',
    'gmail.send_email': 'Enviar e-mail',
    'gmail.create_draft': 'Criar rascunho de e-mail',
    'gmail.get_unread_emails': 'Buscar e-mails não lidos',
    'google_calendar.create_event': 'Criar evento no calendário',
    'google_calendar.list_events': 'Consultar eventos do calendário',
    'google_calendar.update_event': 'Atualizar evento do calendário',
    'google_calendar.delete_event': 'Excluir evento do calendário',
    'google_drive.list_files': 'Consultar arquivos do Drive',
    'google_drive.upload_file': 'Enviar arquivo ao Drive',
    'google_drive.get_file_content': 'Ler arquivo do Drive',
    'google_drive.create_folder': 'Criar pasta no Drive',
    'google_sheets.append_row': 'Adicionar dados à planilha',
    'google_sheets.get_values': 'Consultar dados da planilha',
    'google_sheets.read_range': 'Consultar dados da planilha',
    'google_sheets.update_values': 'Atualizar dados da planilha',
    'google_sheets.create_spreadsheet': 'Criar planilha',
    'http.request': 'Consultar um serviço conectado',
  };

  return labels[moduleId] ?? 'Executar uma etapa da automação';
}

String _friendlyValue(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.contains('{{')) return fallback;
  return text;
}

String friendlyAutomationStepDescription(
  String moduleId,
  Map<String, dynamic> params,
) {
  switch (moduleId) {
    case 'gmail.send_email':
      final recipient = _friendlyValue(
        params['to'],
        'o destinatário definido no pedido',
      );
      final subject = _friendlyValue(
        params['subject'],
        'o assunto definido no pedido',
      );
      return 'Envia um e-mail para $recipient com o assunto “$subject”.';
    case 'gmail.create_draft':
      final recipient = _friendlyValue(
        params['to'],
        'o destinatário definido no pedido',
      );
      return 'Prepara um rascunho de e-mail para $recipient.';
    case 'gmail.get_unread_emails':
      return 'Consulta as mensagens ainda não lidas da conta conectada.';
    case 'google_calendar.create_event':
      final title = _friendlyValue(params['summary'], 'o evento informado');
      return 'Adiciona “$title” ao calendário conectado.';
    case 'google_calendar.list_events':
      return 'Consulta os eventos do período solicitado.';
    case 'google_calendar.update_event':
      return 'Atualiza o evento indicado no calendário.';
    case 'google_calendar.delete_event':
      return 'Remove o evento indicado do calendário.';
    case 'google_drive.create_folder':
      final name = _friendlyValue(params['folder_name'], 'a pasta informada');
      return 'Cria “$name” no Google Drive.';
    case 'google_drive.upload_file':
      final name = _friendlyValue(params['file_name'], 'o arquivo informado');
      return 'Envia “$name” para o Google Drive.';
    case 'google_drive.list_files':
      return 'Consulta os arquivos do Google Drive.';
    case 'google_drive.get_file_content':
      return 'Lê o conteúdo do arquivo escolhido.';
    case 'google_sheets.create_spreadsheet':
      final title = _friendlyValue(params['title'], 'a planilha informada');
      return 'Cria a planilha “$title”.';
    case 'google_sheets.append_row':
      return 'Adiciona uma nova linha à planilha escolhida.';
    case 'google_sheets.get_values':
    case 'google_sheets.read_range':
      return 'Consulta os dados da planilha escolhida.';
    case 'google_sheets.update_values':
      return 'Atualiza os dados da planilha escolhida.';
    case 'flow.wait':
      final duration = _friendlyValue(params['duration'], 'o tempo definido');
      return 'Aguarda $duration antes de continuar.';
    case 'flow.condition':
      return 'Verifica uma condição para decidir quais passos executar.';
    case 'flow.loop':
      return 'Repete os próximos passos conforme o pedido.';
    case 'ai.transform_data':
      return 'Organiza as informações para o próximo passo.';
    default:
      return 'Executa esta ação e segue para o próximo passo.';
  }
}

String friendlyAutomationError(Object error) {
  final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (message.trim().isEmpty) {
    return 'Não foi possível concluir. Tente novamente.';
  }
  return message;
}
