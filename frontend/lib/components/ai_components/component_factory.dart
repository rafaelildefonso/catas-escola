import 'package:flutter/material.dart';

// Components
import 'action_approval.dart';
import 'contact_select.dart';
import 'preview_whatsapp.dart';
import 'preview_email_draft.dart';
import 'preview_calendar_event.dart';
import 'preview_docs.dart';
import 'drive_file_select.dart';
import 'sheets_table_preview.dart';
import 'multiple_choice.dart';
import 'automation_progress.dart';
import 'automation_result.dart';
import 'info_card.dart';
import 'alert_banner.dart';
import 'link_preview.dart';
import 'text_input.dart';
import 'date_time_picker.dart';
import 'editable_preview.dart';
import 'code_block.dart';
import 'checklist.dart';
import 'integration_status.dart';
import 'carousel.dart';
import 'integration_connect.dart';

/// Callback type for when a user interacts with an interactive component.
typedef ComponentResponseCallback =
    void Function(String componentType, Map<String, dynamic> responseData);

class AIComponentFactory extends StatelessWidget {
  final List<dynamic> components;
  final ComponentResponseCallback? onComponentResponse;
  final bool isEnabled;

  const AIComponentFactory({
    super.key,
    required this.components,
    this.onComponentResponse,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: components.map((comp) {
          if (comp is! Map<String, dynamic>) return const SizedBox.shrink();

          String? type;
          Map<String, dynamic>? data;

          if (comp.containsKey('type') &&
              comp['type'] != null &&
              comp['type'].toString().isNotEmpty &&
              comp['type'].toString() != 'null') {
            type = comp['type'] as String?;
            if (comp.containsKey('data')) {
              data = comp['data'] as Map<String, dynamic>?;
            } else {
              // Formato 'flat': remove o type e usa o resto como data
              data = Map<String, dynamic>.from(comp)..remove('type');
            }
          } else if (comp.length == 1 && comp.values.first is Map) {
            // Formato de chave única: {"foo": {}}
            type = comp.keys.first;
            data = comp[type] as Map<String, dynamic>?;
          } else {
            if (comp.containsKey('action') && comp.containsKey('status')) {
              type = 'automation_result';
              data = comp;
            } else if (comp.containsKey('date') && comp.containsKey('time')) {
              type = 'preview_calendar_event';
              data = comp;
            } else if (comp.containsKey('message') &&
                comp.containsKey('phone')) {
              type = 'preview_whatsapp';
              data = comp;
            } else if (comp.containsKey('subject') && comp.containsKey('to')) {
              type = 'preview_email_draft';
              data = comp;
            } else if (comp.containsKey('title') &&
                (comp.containsKey('description') ||
                    comp.containsKey('message'))) {
              // Se tiver 'action' no corpo, é provável que seja aprovação
              if (comp.containsKey('action')) {
                type = 'action_approval';
              } else {
                type = 'alert_banner';
                // Garante que 'message' exista para o AlertBanner
                if (!comp.containsKey('message')) {
                  comp['message'] = comp['description'];
                }
              }
              data = comp;
            } else if (comp.containsKey('provider') ||
                (comp.containsKey('action') &&
                    (comp['action'] == 'connect' ||
                        comp['action'] == 'activate_in_chat'))) {
              type = 'integration_connect';
              data = comp;
            }
          }

          data ??= {};
          final readonly = data['readonly'] as bool? ?? false;

          switch (type) {
            case 'action_approval':
              return ActionApprovalComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
                onResponse: onComponentResponse != null
                    ? (responseData) =>
                          onComponentResponse!('action_approval', responseData)
                    : null,
              );
            case 'contact_select':
              return ContactSelectComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'preview_whatsapp':
              return PreviewWhatsappComponent(data: data, isEnabled: isEnabled);
            case 'preview_email_draft':
              return PreviewEmailDraftComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'preview_calendar_event':
              return PreviewCalendarEventComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'preview_docs':
              return PreviewDocsComponent(data: data, isEnabled: isEnabled);
            case 'drive_file_select':
              return DriveFileSelectComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'sheets_table_preview':
              return SheetsTablePreviewComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'multiple_choice':
              return MultipleChoiceComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'automation_progress':
              return AutomationProgressComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'automation_result':
              return AutomationResultComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'info_card':
              return InfoCardComponent(data: data, isEnabled: isEnabled);
            case 'alert_banner':
              return AlertBannerComponent(data: data, isEnabled: isEnabled);
            case 'link_preview':
              return LinkPreviewComponent(data: data, isEnabled: isEnabled);
            case 'text_input':
              return TextInputComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'date_time_picker':
              return DateTimePickerComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'editable_preview':
              return EditablePreviewComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'code_block':
              return CodeBlockComponent(data: data, isEnabled: isEnabled);
            case 'checklist':
              return ChecklistComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
              );
            case 'integration_status':
              return IntegrationStatusComponent(
                data: data,
                isEnabled: isEnabled,
              );
            case 'carousel':
              return CarouselComponent(data: data, isEnabled: isEnabled);
            case 'integration_connect':
              return IntegrationConnectComponent(
                data: data,
                isEnabled: isEnabled,
                readonly: readonly,
                onResponse: onComponentResponse != null
                    ? (responseData) => onComponentResponse!(
                        'integration_connect',
                        responseData,
                      )
                    : null,
              );
            default:
              // Log para debug mas não quebrar a UI
              if (type != null && type.isNotEmpty) {
                debugPrint(
                  '⚠️ [AIComponentFactory] Componente desconhecido: $type',
                );
              }
              return const SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }
}
