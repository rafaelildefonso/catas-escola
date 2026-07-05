import 'dart:io';
import 'dart:ui';
import 'package:catas/components/brand_logo.dart';
import 'package:catas/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/native_context_provider.dart';
import '../providers/demo_autoplay_controller.dart';
import '../providers/demo_automations_provider.dart';
import '../providers/demo_notifications_provider.dart';
import '../components/demo_timelapse_overlay.dart';
import '../core/app_config.dart';
import '../components/catas_loading_indicator.dart';
import '../components/clickable_wrapper.dart';
import '../components/options_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:file_picker/file_picker.dart';
import '../models/picked_attachment.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/full_screen_viewer.dart';
import 'package:image_picker/image_picker.dart';
import '../components/ai_components/component_factory.dart';
import '../components/integrations_options_menu.dart';
import '../components/integrations_bottom_sheet.dart';
import '../components/attachment_bottom_sheet.dart';
import '../components/picked_attachment_card.dart';
import '../l10n/app_localizations.dart';
import '../components/mention_menu.dart';
import '../screens/integrations_screen.dart'
    show IntegrationItem, IntegrationCategory;
import '../components/catas_dialog.dart';
import '../core/router.dart';
import '../data/suggested_prompts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _inputVazio = true;
  final ImagePicker _imagePicker = ImagePicker();
  bool _onboardingAhaChecked = false;
  static const int _maxInputLength = 2000;

  final LayerLink _mentionLayerLink = LayerLink();
  OverlayEntry? _mentionOverlayEntry;
  String _mentionQuery = '';
  int? _mentionStartIndex;

  // Demo mode state
  bool _showTimelapse = false;
  bool _demoButtonClicked = false;
  DemoAutoplayController? _autoplayController;
  bool _isAutoplayTyping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppConfig.isDemoMode && _autoplayController == null) {
      _autoplayController = context.read<DemoAutoplayController>();
      _autoplayController!.onShowTimelapse(() {
        setState(() => _showTimelapse = true);
      });
      _autoplayController!.onShowNotification(() {
        _triggerDemoNotification();
        setState(() => _showTimelapse = false);
      });
      _autoplayController!.onSendMessage(() {
        if (mounted) {
          debugPrint(
            'ChatScreen: Sending demo message, controller text: "${_controller.text}"',
          );
          _sendMessage();
        }
      });
      _autoplayController!.onFillComponent((componentType, value) {
        if (mounted) {
          debugPrint(
            'ChatScreen: Filling component $componentType with "$value"',
          );
          // Send component response directly (not chat message)
          final chatProv = Provider.of<ChatProvider>(context, listen: false);
          chatProv.sendComponentResponse(componentType, {
            'field_id': 'sheet_name',
            'text': value,
          });
        }
      });
      _autoplayController!.onApproveAction(() {
        if (mounted) {
          debugPrint('ChatScreen: Clicking approve button');
          // Find and click the approve button in the last message
          _clickApproveButton();
        }
      });
      _autoplayController!.onAddAutomation(() {
        if (mounted) {
          debugPrint('ChatScreen: Adding automation');
          final demoAutoProvider = context.read<DemoAutomationsProvider>();
          demoAutoProvider.addReportAutomation();
        }
      });
      _autoplayController!.onNavigateToAutomationDetail(() {
        if (mounted) {
          final demoAutoProvider = context.read<DemoAutomationsProvider>();
          final runId = demoAutoProvider.lastOnboardingRunId;
          if (runId != null) {
            context.push(AppRoutes.automationDetailPath(runId));
          }
        }
      });

      _autoplayController!.addListener(_onAutoplayChanged);
    }
  }

  void _onAutoplayChanged() {
    if (!mounted || _autoplayController == null) return;
    final typingText = _autoplayController!.currentTypingText;
    final isTyping = _autoplayController!.state == DemoAutoplayState.typing;
    if (isTyping && typingText != null) {
      _isAutoplayTyping = true;
      _controller.text = typingText;
      _controller.selection = TextSelection.collapsed(offset: typingText.length);
      if (_inputVazio && typingText.isNotEmpty) {
        _inputVazio = false;
      }
      _isAutoplayTyping = false;
    }
  }

  void _clickApproveButton() {
    // Send component response for action_approval with approved: true
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendComponentResponse('action_approval', {'approved': true});
  }

  void _triggerDemoNotification() {
    final demoNotifProvider = context.read<DemoNotificationsProvider>();
    demoNotifProvider.addReportReadyNotification();
    // Also add the automation to the list
    final demoAutoProvider = context.read<DemoAutomationsProvider>();
    demoAutoProvider.addReportAutomation();
  }

  void _startOnboardingAutoplay() {
    debugPrint('Onboarding Demo button pressed');
    if (_autoplayController == null) {
      debugPrint('ERROR: _autoplayController is null');
      return;
    }
    if (_autoplayController!.isRunning) {
      debugPrint('Demo already running, ignoring');
      return;
    }
    setState(() => _demoButtonClicked = true);
    debugPrint('Starting onboarding demo autoplay...');
    _autoplayController!.startOnboardingDemo();
  }

  Future<void> _runPendingOnboardingAha() async {
    if (_onboardingAhaChecked || !mounted) return;
    _onboardingAhaChecked = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboarding_aha_pending') != true) return;
    await prefs.remove('onboarding_aha_pending');
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final industry = authProvider.profile?.industry ?? 'other';

    String message =
        'CATAS: quero criar minha primeira automação de demonstração — um lembrete simples para começar.';

    if (industry == 'real_estate') {
      message =
          'CATAS: Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.';
    } else if (industry == 'marketing') {
      message =
          'CATAS: Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.';
    } else if (industry == 'legal') {
      message =
          'CATAS: Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.';
    }

    await context.read<ChatProvider>().sendMessage(message);
  }

  static const List<IntegrationItem> _availableIntegrations = [
    IntegrationItem(
      title: 'Google Calendar',
      logoId: LogoId.googleCalendar,
      providerName: 'google_calendar',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Sheets',
      logoId: LogoId.googleSheets,
      providerName: 'google_sheets',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Drive',
      logoId: LogoId.googleDrive,
      providerName: 'google_drive',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Docs',
      logoId: LogoId.googleDocs,
      providerName: 'google_docs',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Notion',
      logoId: LogoId.notion,
      providerName: 'notion',
      category: [IntegrationCategory.productivity],
    ),
    IntegrationItem(
      title: 'Gmail',
      logoId: LogoId.googleGmail,
      providerName: 'google_gmail',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Meet',
      logoId: LogoId.googleMeet,
      providerName: 'google_meet',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Whatsapp',
      logoId: LogoId.whatsapp,
      providerName: 'whatsapp',
      category: [IntegrationCategory.communication],
    ),
    IntegrationItem(
      title: 'Slack',
      logoId: LogoId.slack,
      providerName: 'slack',
      category: [IntegrationCategory.communication],
    ),
  ];

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _removeMentionOverlay() {
    _mentionOverlayEntry?.remove();
    _mentionOverlayEntry?.dispose();
    _mentionOverlayEntry = null;
    _mentionStartIndex = null;
    _mentionQuery = '';
  }

  void _handleMentionLookups() {
    if (!mounted) return;

    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeMentionOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > text.length) return;

    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtPos = textBeforeCursor.lastIndexOf('@');
    if (lastAtPos != -1) {
      if (lastAtPos == 0 ||
          textBeforeCursor[lastAtPos - 1] == ' ' ||
          textBeforeCursor[lastAtPos - 1] == '\n') {
        final query = textBeforeCursor.substring(lastAtPos + 1);
        if (!query.contains(' ') && !query.contains('\n')) {
          _mentionStartIndex = lastAtPos;
          _mentionQuery = query.toLowerCase();
          _showMentionOverlay();
          return;
        }
      }
    }

    _removeMentionOverlay();
  }

  void _showMentionOverlay() {
    if (_mentionStartIndex == null) return;

    final filtered = _availableIntegrations
        .where((item) => item.title.toLowerCase().contains(_mentionQuery))
        .toList();

    if (filtered.isEmpty) {
      _removeMentionOverlay();
      return;
    }

    if (_mentionOverlayEntry == null) {
      _mentionOverlayEntry = OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: Clickable(
                  onTap: _removeMentionOverlay,
                  child: SizedBox.expand(),
                ),
              ),
              Positioned(
                child: CompositedTransformFollower(
                  link: _mentionLayerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.topRight,
                  followerAnchor: Alignment.bottomRight,
                  offset: const Offset(
                    -16,
                    -8,
                  ), // Align with the right of the input container
                  child: MentionMenu(
                    items: filtered,
                    onSelect: _onMentionSelect,
                  ),
                ),
              ),
            ],
          );
        },
      );
      Overlay.of(context).insert(_mentionOverlayEntry!);
    } else {
      _mentionOverlayEntry!.markNeedsBuild();
    }
  }

  void _onMentionSelect(IntegrationItem item) {
    if (_mentionStartIndex == null) return;

    final text = _controller.text;
    final replacement = '@${item.title} ';

    final newText = text.replaceRange(
      _mentionStartIndex!,
      _controller.selection.baseOffset,
      replacement,
    );

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: _mentionStartIndex! + replacement.length,
    );

    _removeMentionOverlay();

    final provider = context.read<ChatProvider>();
    if (!provider.activeIntegrations.contains(item.providerName)) {
      provider.toggleChatIntegration(item.providerName);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(AppLocalizations.of(context)!.copied);
  }

  Future<void> _showSelectableTextDialog(String text) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.text),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              _showSnack(AppLocalizations.of(context)!.copied);
            },
            child: Text(AppLocalizations.of(context)!.copy),
          ),
        ],
      ),
    );
  }

  Future<void> _showMessageActions(
    BuildContext context,
    Offset tapPosition,
    Message message,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final items = message.isUser
        ? [
            CatasOptionItem(
              value: 'edit',
              icon: Icons.edit_outlined,
              label: l10n.edit,
            ),
            CatasOptionItem(
              value: 'copy',
              icon: Icons.copy_all_outlined,
              label: l10n.copy,
            ),
          ]
        : [
            CatasOptionItem(
              value: 'copy',
              icon: Icons.copy_all_outlined,
              label: l10n.copy,
            ),
            CatasOptionItem(
              value: 'share',
              icon: Icons.share_outlined,
              label: l10n.share,
            ),
          ];

    final selectedValue = await CatasOptionsMenu.show(
      context: context,
      items: items,
      position: tapPosition,
      onSelected: (_) {},
    );

    if (!mounted || selectedValue == null) return;

    switch (selectedValue) {
      case 'edit':
        setState(() {
          _controller.text = message.text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          _inputVazio = _controller.text.isEmpty;
        });
        break;
      case 'copy':
        await _copyToClipboard(message.text);
        break;
      case 'select':
        await _showSelectableTextDialog(message.text);
        break;
      case 'share':
        await SharePlus.instance.share(ShareParams(text: message.text));
        break;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAttachments(List<String> urls) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: urls.map((url) {
          final isLocal = !url.startsWith('http');
          final isImage =
              isLocal &&
              (url.toLowerCase().endsWith('.jpg') ||
                  url.toLowerCase().endsWith('.jpeg') ||
                  url.toLowerCase().endsWith('.png') ||
                  url.toLowerCase().endsWith('.gif') ||
                  url.toLowerCase().endsWith('.webp'));

          return Clickable(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenViewer(url: url, tag: url),
                ),
              );
            },
            child: Hero(
              tag: url,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: isLocal
                      ? (isImage
                            ? Image.file(File(url), fit: BoxFit.cover)
                            : const Center(
                                child: Icon(Icons.insert_drive_file_outlined),
                              ))
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error_outline),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newAttachments = result.files.where((f) => f.path != null).map((
          f,
        ) {
          final isImage = [
            'jpg',
            'jpeg',
            'png',
            'webp',
            'gif',
          ].any((ext) => f.name.toLowerCase().endsWith(ext));
          return PickedAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString() + f.name,
            path: f.path!,
            name: f.name,
            isImage: isImage,
            bytes: f.bytes,
          );
        }).toList();

        if (newAttachments.isNotEmpty) {
          if (!mounted) return;
          context.read<ChatProvider>().addAttachments(newAttachments);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showSnack('${l10n.errorSelectDocument} $e');
    }
  }

  void _showIntegrationOptions() {
    if (kIsWeb) {
      IntegrationsOptionsMenu.show(context);
    } else {
      IntegrationsBottomSheet.show(context);
    }
  }

  void _showAttachmentMenu(BuildContext buttonContext) {
    if (kIsWeb) {
      final RenderBox button = buttonContext.findRenderObject() as RenderBox;
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final Offset globalOffset = button.localToGlobal(Offset.zero, ancestor: overlay);
      CatasOptionsMenu.show(
        context: context,
        position: globalOffset,
        items: const [
          CatasOptionItem(
            value: 'camera',
            icon: Icons.camera_alt_outlined,
            label: 'Câmera',
          ),
          CatasOptionItem(
            value: 'gallery',
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
          ),
          CatasOptionItem(
            value: 'file',
            icon: Icons.insert_drive_file_outlined,
            label: 'Arquivos',
          ),
        ],
        onSelected: (selected) {
          if (!mounted) return;
          switch (selected) {
            case 'camera':
              _pickImage(ImageSource.camera);
              break;
            case 'gallery':
              _pickImage(ImageSource.gallery);
              break;
            case 'file':
              _pickDocument();
              break;
          }
        },
      );
    } else {
      AttachmentBottomSheet.show(
        context,
        onCameraTap: () => _pickImage(ImageSource.camera),
        onGalleryTap: () => _pickImage(ImageSource.gallery),
        onFileTap: () => _pickDocument(),
      );
    }
  }

  Future<void> _loadIntegrationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final chatProvider = context.read<ChatProvider>();

    final integrations = [
      'google_calendar',
      'google_drive',
      'google_docs',
      'google_gmail',
      'google_meet',
      'notion',
      'whatsapp',
      'slack',
    ];

    for (final provider in integrations) {
      final key = 'integration_active_$provider';
      final isActive = prefs.getBool(key);

      if (isActive == null) {
        await prefs.setBool(key, true);
        if (!chatProvider.isIntegrationActive(provider)) {
          chatProvider.toggleChatIntegration(provider);
        }
      } else if (isActive && !chatProvider.isIntegrationActive(provider)) {
        chatProvider.toggleChatIntegration(provider);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          final newAttachments = images
              .map(
                (image) => PickedAttachment(
                  id:
                      DateTime.now().millisecondsSinceEpoch.toString() +
                      image.name,
                  path: image.path,
                  name: image.name,
                  isImage: true,
                ),
              )
              .toList();
          if (!mounted) return;
          context.read<ChatProvider>().addAttachments(newAttachments);
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          if (!mounted) return;
          context.read<ChatProvider>().addAttachments([
            PickedAttachment(
              id: DateTime.now().millisecondsSinceEpoch.toString() + image.name,
              path: image.path,
              name: image.name,
              isImage: true,
            ),
          ]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showSnack('${l10n.errorSelectImage} $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final chatProvider = context.read<ChatProvider>();
    if (text.isEmpty && chatProvider.attachments.isEmpty) return;

    if (chatProvider.isLoading) return;

    // Fechar overlays e modais (especialmente importante para Desktop/Enter)
    _removeMentionOverlay();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && !modalRoute.isCurrent) {
      Navigator.of(context).pop();
    }

    // Read native context (no-op on web — provider returns null)
    final nativeCtx = context.read<NativeContextProvider>();

    chatProvider.sendMessage(
      text,
      currentPageUrl: nativeCtx.currentPageUrl,
      currentPageTitle: nativeCtx.currentPageTitle,
    );
    _controller.clear();
    // O sendMessage agora limpa o draft e anexos internamente de forma imediata
    _scrollToBottom();
  }

  late List<SuggestedPrompt> _shuffledPrompts;

  @override
  void initState() {
    super.initState();
    _initShuffledPrompts();
    _loadIntegrationPreferences();

    if (kIsWeb) {
      _focusNode.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          if (!HardwareKeyboard.instance.isShiftPressed) {
            _sendMessage();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _runPendingOnboardingAha();
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();

      // Carregar rascunho de texto
      if (chatProvider.messageDraft.isNotEmpty) {
        _controller.text = chatProvider.messageDraft;
        _inputVazio = false;
      }

      _focusNode.requestFocus();
      _handleRouteChange();
    });

    _controller.addListener(() {
      if (_isAutoplayTyping) return;
      final text = _controller.text;
      final isEmpty = text.trim().isEmpty;
      if (isEmpty != _inputVazio) {
        _inputVazio = isEmpty;
      }
      // Salva o rascunho no provider
      context.read<ChatProvider>().setMessageDraft(text);
      _handleMentionLookups();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 100) {
      final chatProvider = context.read<ChatProvider>();
      if (!chatProvider.isLoading &&
          !chatProvider.isLoadingMoreMessages &&
          chatProvider.hasMoreMessages) {
        chatProvider.loadMoreMessages();
      }
    }
  }

  void _initShuffledPrompts() {
    final prompts = List<SuggestedPrompt>.from(SuggestedPromptsData.prompts);
    prompts.shuffle();
    _shuffledPrompts = prompts.take(3).toList();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleRouteChange();
  }

  void _handleRouteChange() {
    final state = GoRouterState.of(context);
    final sessionId = state.pathParameters['sessionId'];
    final chatProvider = context.read<ChatProvider>();

    if (sessionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final prov = context.read<ChatProvider>();
          if (prov.currentSessionId != sessionId) {
            prov.switchSession(sessionId);
          }
        }
      });
    } else if (state.matchedLocation == '/' ||
        state.matchedLocation == AppRoutes.chat) {
      if (chatProvider.messages.isEmpty &&
          chatProvider.currentSessionId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            chatProvider.clearChat();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _removeMentionOverlay();
    _autoplayController?.removeListener(_onAutoplayChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatProvider = context.watch<ChatProvider>();
    final allMessages = chatProvider.messages;
    final messages = allMessages.where((m) => !m.isHidden).toList();
    final isLoading = chatProvider.isLoading;
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final bool isOnboardingSession =
        (chatProvider.currentSession?.isOnboarding ?? false) ||
        (allMessages.isNotEmpty &&
            allMessages.first.role == 'user' &&
            allMessages.first.text.trim() ==
                'CATAS: quero criar minha primeira automação de demonstração — um lembrete simples para começar.');

    // No longer updating URL here to avoid loops, ChatScreen handles state sync from URL

    if (messages.isNotEmpty) _scrollToBottom();

    final currentLength = _controller.text.length;
    final progress = currentLength / _maxInputLength;
    Color inputBorderColor = colorScheme.outline.withValues(alpha: 0.15);
    if (progress > 0.7) {
      final intensity = (progress - 0.7) / 0.3;
      inputBorderColor = Color.lerp(
        inputBorderColor,
        Colors.redAccent,
        intensity,
      )!;
    }

    String getGreeting() {
      int hour = DateTime.now().hour;
      String dayHour = hour < 12
          ? l10n.goodMorning(auth.userFirstName ?? "")
          : hour < 18
          ? l10n.goodAfternoon(auth.userFirstName ?? "")
          : l10n.goodEvening(auth.userFirstName ?? "");
      if (messages.isNotEmpty) {
        return "";
      }

      return dayHour;
    }

    final bool isCenteredEmptyState =
        kIsWeb &&
        messages.isEmpty &&
        chatProvider.currentSessionId == null &&
        !isLoading;

    return Stack(
      children: [
        Column(
          children: [
            if (isCenteredEmptyState) ...[
              const Spacer(),
              _buildEmptyState(auth, getGreeting()),
              const SizedBox(height: 16),
            ] else ...[
              // Chat Area
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: messages.isEmpty
                            ? (isLoading
                                  ? _buildHistorySkeleton()
                                  : (!kIsWeb &&
                                        chatProvider.currentSessionId == null)
                                  // Mobile empty state: greeting + chips
                                  ? _buildMobileEmptyState(auth, getGreeting())
                                  : Center(
                                      child: Text(
                                        l10n.noMessages,
                                        style: GoogleFonts.inter(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ))
                            : ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 24,
                                ),
                                itemCount:
                                    messages.length +
                                    (isLoading ? 1 : 0) +
                                    (chatProvider.isLoadingMoreMessages
                                        ? 1
                                        : 0),
                                separatorBuilder: (c, i) =>
                                    const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                  if (chatProvider.isLoadingMoreMessages) {
                                    if (index == 0) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    index--;
                                  }
                                  if (index == messages.length) {
                                    return _buildLoadingIndicator();
                                  }
                                  final message = messages[index];
                                  return _buildMessageRow(
                                    message,
                                    index,
                                    messages,
                                    isLoading,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Input Area (Omnibox Style)
            CompositedTransformTarget(
              link: _mentionLayerLink,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                color: Colors.transparent, // Floating feel
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                            // .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: inputBorderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 6,
                            right: 6,
                            top: 4,
                            bottom: 4,
                          ),
                          child:
                              auth.subscriptionTier == 'free' &&
                                  !isOnboardingSession
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        l10n.aiExclusive,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () =>
                                            context.go(AppRoutes.pricing),
                                        icon: const Icon(
                                          Icons.bolt_rounded,
                                          size: 20,
                                        ),
                                        label: Text(l10n.unlockAccess),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (chatProvider.attachments.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          top: 8,
                                          bottom: 4,
                                          right: 12,
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: chatProvider.attachments
                                              .map(
                                                (
                                                  attachment,
                                                ) => PickedAttachmentCard(
                                                  attachment: attachment,
                                                  onRemove: () => chatProvider
                                                      .removeAttachment(
                                                        attachment.id,
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: kIsWeb
                                                  ? KeyboardListener(
                                                      focusNode: FocusNode(),
                                                      onKeyEvent: (KeyEvent event) {
                                                        if (event
                                                                is KeyDownEvent &&
                                                            event.logicalKey ==
                                                                LogicalKeyboardKey
                                                                    .enter) {
                                                          if (!HardwareKeyboard
                                                              .instance
                                                              .isShiftPressed) {
                                                            _sendMessage();
                                                          }
                                                        }
                                                      },
                                                      child: TextField(
                                                        controller:
                                                            _controller,
                                                        focusNode: _focusNode,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 15,
                                                            ),
                                                        enabled: !isLoading,
                                                        minLines: 1,
                                                        maxLines: 5,
                                                        textInputAction:
                                                            TextInputAction
                                                                .newline,
                                                        maxLength:
                                                            _maxInputLength,
                                                        cursorColor: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        decoration: InputDecoration(
                                                          hintText: l10n
                                                              .askAnything,
                                                          filled: false,
                                                          counterText: '',
                                                          border: InputBorder
                                                              .none,
                                                          disabledBorder:
                                                              InputBorder
                                                                  .none,
                                                          focusedBorder:
                                                              InputBorder
                                                                  .none,
                                                          errorBorder:
                                                              InputBorder
                                                                  .none,
                                                          focusedErrorBorder:
                                                              InputBorder
                                                                  .none,
                                                          enabledBorder:
                                                              InputBorder
                                                                  .none,
                                                          hintStyle: GoogleFonts.inter(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurfaceVariant
                                                                    .withValues(
                                                                      alpha:
                                                                          0.6,
                                                                    ),
                                                          ),
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                                horizontal:
                                                                    16,
                                                              ),
                                                          isDense: true,
                                                        ),
                                                        onSubmitted: (_) =>
                                                            _sendMessage(),
                                                      ),
                                                    )
                                                  : TextField(
                                                      controller: _controller,
                                                      focusNode: _focusNode,
                                                      style:
                                                          GoogleFonts.inter(
                                                            fontSize: 15,
                                                          ),
                                                      enabled: !isLoading,
                                                      minLines: 1,
                                                      maxLines: 5,
                                                      textInputAction:
                                                          TextInputAction
                                                              .newline,
                                                      cursorColor: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      decoration: InputDecoration(
                                                        hintText:
                                                            l10n.askAnything,
                                                        filled: false,
                                                        border:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
                                                        focusedErrorBorder:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        hintStyle: GoogleFonts.inter(
                                                          color:
                                                              Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .onSurfaceVariant
                                                                  .withValues(
                                                                    alpha:
                                                                        0.6,
                                                                  ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                              horizontal: 16,
                                                            ),
                                                        isDense: true,
                                                      ),
                                                      onSubmitted: (_) =>
                                                          _sendMessage(),
                                                    ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Attach Button
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Builder(
                                                builder: (ctx) => IconButton(
                                                  onPressed: isLoading
                                                      ? null
                                                      : () =>
                                                            _showAttachmentMenu(
                                                              ctx,
                                                            ),
                                                  icon: Icon(
                                                    Icons.add_rounded,
                                                    size: 24,
                                                    color: isLoading
                                                        ? colorScheme
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                alpha: 0.4,
                                                              )
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                  ),
                                                  tooltip: 'Abrir Anexos',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Integrations Button
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: IconButton(
                                                onPressed:
                                                    _showIntegrationOptions,
                                                icon: Icon(
                                                  Icons.device_hub,
                                                  size: 20,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                tooltip: 'Abrir Integrações',
                                              ),
                                            ),
                                            Expanded(
                                              child:
                                                  (currentLength >
                                                      _maxInputLength * 0.5)
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 12,
                                                            bottom: 8,
                                                          ),
                                                      child: Text(
                                                        '$currentLength / $_maxInputLength',
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              progress > 0.7
                                                              ? inputBorderColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.9,
                                                                    )
                                                              : colorScheme
                                                                    .onSurfaceVariant
                                                                    .withValues(
                                                                      alpha:
                                                                          0.4,
                                                                    ),
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ),
                                            // Stop/Send/Mic Button
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 3,
                                                right: 3,
                                              ),
                                              child: isLoading
                                                  // Botão de Stop durante loading
                                                  ? Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration:
                                                          BoxDecoration(
                                                            color: Colors
                                                                .red[400],
                                                            shape: BoxShape
                                                                .circle,
                                                          ),
                                                      child: IconButton(
                                                        onPressed: () async {
                                                          final provider =
                                                              context
                                                                  .read<
                                                                    ChatProvider
                                                                  >();
                                                          bool shouldStop =
                                                              true;
                        
                                                          // Se estiver em fase crítica de automação, pede confirmação
                                                          if (provider.thinkingStage ==
                                                                  ThinkingStage
                                                                      .planning ||
                                                              provider.thinkingStage ==
                                                                  ThinkingStage
                                                                      .executing) {
                                                            final confirmed = await showCatasDialog<bool>(
                                                              context:
                                                                  context,
                                                              title:
                                                                  "Parar agora?",
                                                              message:
                                                                  "Uma automação está sendo preparada ou executada. Parar agora cancelará todo o progresso.",
                                                              actionsBuilder: (context) => [
                                                                CatasDialogAction(
                                                                  label:
                                                                      "Continuar",
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                                  isSecondary:
                                                                      true,
                                                                ),
                                                                CatasDialogAction(
                                                                  label:
                                                                      "Parar Tudo",
                                                                  isDestructive:
                                                                      true,
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                                ),
                                                              ],
                                                            );
                                                            shouldStop =
                                                                confirmed ??
                                                                false;
                                                          }
                        
                                                          if (shouldStop) {
                                                            provider
                                                                .stopGeneration();
                                                            _showSnack(
                                                              l10n.generationInterrupted,
                                                            );
                                                          }
                                                        },
                                                        iconSize: 24,
                                                        icon: const Icon(
                                                          Icons.stop_rounded,
                                                          size: 20,
                                                          color: Colors.white,
                                                        ),
                                                        tooltip: l10n
                                                            .stopGeneration,
                                                      ),
                                                    )
                                                  // Botão de envio ou microfone
                                                  : !_inputVazio
                                                  ? Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        shape:
                                                            BoxShape.circle,
                                                      ),
                                                      child: IconButton(
                                                        onPressed:
                                                            _sendMessage,
                                                        iconSize: 24,
                                                        icon: Icon(
                                                          Icons
                                                              .arrow_upward_rounded,
                                                          size: 20,
                                                          color:
                                                              Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .onPrimary,
                                                        ),
                                                      ),
                                                    )
                                                  : IconButton(
                                                      onPressed: () => {
                                                        _showSnack(
                                                          l10n.audioComingSoon,
                                                        ),
                                                      },
                                                      iconSize: 24,
                                                      icon: Icon(
                                                        Icons
                                                            .mic_none_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      tooltip:
                                                          l10n.recordAudio,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Prompt chips (web only, below input)
            if (isCenteredEmptyState && auth.subscriptionTier != 'free')
              _buildPromptChips(),

            if (isCenteredEmptyState) const Spacer(flex: 2),
          ],
        ),

        // Demo Play Button (Onboarding)
        if (AppConfig.isDemoMode &&
            !_showTimelapse &&
            !_demoButtonClicked &&
            !(_autoplayController?.isRunning ?? false))
          Positioned(
            right: 24,
            bottom: 180,
            child: FloatingActionButton(
              onPressed: _startOnboardingAutoplay,
              heroTag: 'demo_onboarding',
              child: const Icon(Icons.rocket_launch_rounded),
            ),
          ),

        // Timelapse Overlay
        if (_showTimelapse)
          Positioned.fill(
            child: DemoTimelapseOverlay(
              onComplete: () => setState(() => _showTimelapse = false),
            ),
          ),
      ],
    );
  }

  Widget _buildThinkingStep(
    String label,
    IconData icon,
    bool isActive,
    bool isDone,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.1)
                : isDone
                ? Colors.green.withValues(alpha: 0.1)
                : colorScheme.onSurface.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 12,
            color: isActive
                ? colorScheme.primary
                : isDone
                ? Colors.green
                : colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    final l10n = AppLocalizations.of(context)!;
    final chatProvider = context.watch<ChatProvider>();
    final stage = chatProvider.thinkingStage;
    final automationSteps = chatProvider.automationSteps;
    final colorScheme = Theme.of(context).colorScheme;

    if (stage == ThinkingStage.idle && automationSteps.isEmpty) {
      if (chatProvider.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: CatasLoadingIndicator(),
        );
      }
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dinamic Stepper
                  if (stage != ThinkingStage.processing &&
                      automationSteps.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (stage == ThinkingStage.reasoning ||
                              stage == ThinkingStage.planning ||
                              stage == ThinkingStage.executing)
                            _buildThinkingStep(
                              l10n.thinkingReasoning,
                              Icons.psychology_outlined,
                              stage == ThinkingStage.reasoning,
                              stage == ThinkingStage.planning ||
                                  stage == ThinkingStage.executing,
                              colorScheme,
                            ),
                          if (stage == ThinkingStage.planning ||
                              stage == ThinkingStage.executing)
                            _buildThinkingStep(
                              l10n.thinkingPlanning,
                              Icons.architecture_outlined,
                              stage == ThinkingStage.planning,
                              stage == ThinkingStage.executing,
                              colorScheme,
                            ),
                          if (stage == ThinkingStage.executing)
                            _buildThinkingStep(
                              l10n.thinkingExecuting,
                              Icons.bolt_outlined,
                              true,
                              false,
                              colorScheme,
                            ),
                        ],
                      ),
                    )
                  else if (stage == ThinkingStage.processing)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.thinkingProcessing,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                  // Automation specific steps (if any)
                  if (automationSteps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            automationSteps.first['intent'] ??
                                l10n.executingAutomation,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...automationSteps.map((step) {
                            final status = step['status'] as String;
                            final isRunning = status == 'running';
                            final isSuccess = status == 'success';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  if (isRunning)
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  else
                                    Icon(
                                      isSuccess
                                          ? Icons.check_circle
                                          : Icons.error,
                                      size: 12,
                                      color: isSuccess
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    step['module_id'] ?? "Step",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isRunning
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isRunning
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: 4,
        separatorBuilder: (c, i) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final isUser = index % 2 == 0;
          final mockMessages = List.generate(
            4,
            (i) => Message(text: "...", isUser: i % 2 == 0),
          );
          return _buildMessageRow(
            Message(
              text: "Este é um texto de exemplo para o skeleton loader...",
              isUser: isUser,
            ),
            index,
            mockMessages,
            false,
          );
        },
      ),
    );
  }

  // Removido _examplePrompts estático em favor do SuggestedPromptsData

  Widget _buildEmptyState(AuthProvider auth, String greeting) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.howCanIHelp,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Mobile empty state: greeting + chips (layout original do mobile)
  Widget _buildMobileEmptyState(AuthProvider auth, String greeting) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.howCanIHelp,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Chips de sugestão no mobile ficam acima do input (abaixo do greeting)
        if (auth.subscriptionTier != 'free')
          AnimatedOpacity(
            opacity: _inputVazio ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 12,
                  children: [
                    ..._shuffledPrompts.map(
                      (item) =>
                          _buildPromptSuggestions(item.prompt, item.logos),
                    ),
                    _buildSeeMorePromptsChip(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromptChips() {
    return AnimatedOpacity(
      opacity: _inputVazio ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, 800.0)
                : 800.0;
            return SizedBox(
              width: width,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 12,
                  children: [
                    ..._shuffledPrompts.map(
                      (item) =>
                          _buildPromptSuggestions(item.prompt, item.logos),
                    ),
                    _buildSeeMorePromptsChip(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromptSuggestions(String prompt, List<LogoId> integrations) {
    return InkWell(
      onTap: () {
        _controller.text = prompt;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                prompt,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.3,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: List.generate(integrations.length, (index) {
                return Logo(
                  logoId: integrations[index],
                  size: 20,
                  onErrorIcon: const Icon(Icons.auto_awesome, size: 16),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeMorePromptsChip() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final result = await context.push<String>('/prompts');
        if (result != null && result.isNotEmpty) {
          setState(() {
            _controller.text = result;
            _inputVazio = false;
          });
          _focusNode.requestFocus();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.dashboardSeeMore,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dashboardExplorePrompts,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(
    Message message,
    int index,
    List<Message> messages,
    bool isLoading,
  ) {
    final l10n = AppLocalizations.of(context)!;
    Offset? tapPosition;

    if (message.isUser) {
      // User Message (Right aligned, subtle bubble)
      return Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTapDown: (details) => tapPosition = details.globalPosition,
          onLongPress: kIsWeb
              ? null
              : () {
                  if (tapPosition != null) {
                    _showMessageActions(context, tapPosition!, message);
                  }
                },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.attachmentUrls != null &&
                        message.attachmentUrls!.isNotEmpty)
                      _buildAttachments(message.attachmentUrls!),
                    SelectionArea(
                      child: Text(
                        message.text,
                        style: GoogleFonts.inter(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Ações visíveis apenas na web (mobile usa long-press)
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 24, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInlineActionButton(
                        icon: Icons.edit_outlined,
                        tooltip: l10n.edit,
                        onTap: () {
                          setState(() {
                            _controller.text = message.text;
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length),
                            );
                            _inputVazio = _controller.text.isEmpty;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildInlineActionButton(
                        icon: Icons.copy_all_outlined,
                        tooltip: l10n.copy,
                        onTap: () => _copyToClipboard(message.text),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // AI Message (Left aligned, No bubble, Full width feel)
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (message.attachmentUrls != null &&
                          message.attachmentUrls!.isNotEmpty)
                        _buildAttachments(message.attachmentUrls!),
                      if (message.chunks.isNotEmpty)
                        for (int i = 0; i < message.chunks.length; i++) ...[
                          SelectionArea(
                            child: MarkdownBody(
                              data: message.chunks[i].text,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.inter(
                                  height: 1.6,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                          if (message.chunks[i].components != null &&
                              message.chunks[i].components!.isNotEmpty)
                            AIComponentFactory(
                              components: message.chunks[i].components!,
                              isEnabled:
                                  !isLoading &&
                                  index == messages.length - 1 &&
                                  i == message.chunks.length - 1,
                              onComponentResponse: (type, data) {
                                final chatProv = Provider.of<ChatProvider>(
                                  context,
                                  listen: false,
                                );
                                chatProv.sendComponentResponse(type, data);
                              },
                            ),
                          if (i < message.chunks.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.1),
                                thickness: 1,
                              ),
                            ),
                        ]
                      else ...[
                        SelectionArea(
                          child: MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.inter(
                                height: 1.6,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        if (message.components != null &&
                            message.components!.isNotEmpty)
                          AIComponentFactory(
                            components: message.components!,
                            isEnabled:
                                !isLoading && index == messages.length - 1,
                            onComponentResponse: (type, data) {
                              final chatProv = Provider.of<ChatProvider>(
                                context,
                                listen: false,
                              );
                              chatProv.sendComponentResponse(type, data);
                            },
                          ),
                      ],
                      if (message.actionTriggered &&
                          message.actionDetails != null &&
                          (message.components == null ||
                              message.components!.isEmpty))
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.actionExecuted,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Tool Name
                              if (message.actionDetails!['tool'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.integration_instructions,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        message.actionDetails!['tool'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Payload Visual Feedback (Slot Filling)
                              if (message.actionDetails!['payload'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildPayloadDetails(
                                    message.actionDetails!['payload'],
                                    context,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else if (message.actionTriggered &&
                          (message.components == null ||
                              message.components!.isEmpty))
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.actionExecuted,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // --- Inline Action Buttons (web) ---
                      if (kIsWeb)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              _buildInlineActionButton(
                                icon: Icons.copy_all_outlined,
                                tooltip: l10n.copy,
                                onTap: () => _copyToClipboard(message.text),
                              ),
                              const SizedBox(width: 8),
                              _buildInlineActionButton(
                                icon: Icons.share_outlined,
                                tooltip: l10n.share,
                                onTap: () async {
                                  await SharePlus.instance.share(
                                    ShareParams(text: message.text),
                                  );
                                },
                              ),
                              const Spacer(),
                              if (message.isFinalResponse &&
                                  message.canReceiveFeedback) ...[
                                IconButton(
                                  onPressed: () {
                                    final chatProv = Provider.of<ChatProvider>(
                                      context,
                                      listen: false,
                                    );
                                    chatProv.sendFeedback(message, true);
                                  },
                                  icon: Icon(
                                    message.isLiked == true
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    size: 18,
                                  ),
                                  color: message.isLiked == true
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  tooltip: l10n.like,
                                ),
                                IconButton(
                                  onPressed: () {
                                    final chatProv = Provider.of<ChatProvider>(
                                      context,
                                      listen: false,
                                    );
                                    chatProv.sendFeedback(message, false);
                                  },
                                  icon: Icon(
                                    message.isLiked == false
                                        ? Icons.thumb_down
                                        : Icons.thumb_down_outlined,
                                    size: 18,
                                  ),
                                  color: message.isLiked == false
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  tooltip: l10n.dislike,
                                ),
                              ],
                            ],
                          ),
                        ),
                      // --- Feedback (mobile: only for final responses) ---
                      if (!kIsWeb &&
                          message.isFinalResponse &&
                          message.canReceiveFeedback)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              // --- Ações (web e mobile: sempre visíveis) ---
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 8),
                                child: Row(
                                  children: [
                                    _buildInlineActionButton(
                                      icon: Icons.copy_all_outlined,
                                      tooltip: l10n.copy,
                                      onTap: () =>
                                          _copyToClipboard(message.text),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInlineActionButton(
                                      icon: Icons.share_outlined,
                                      tooltip: l10n.share,
                                      onTap: () async {
                                        await SharePlus.instance.share(
                                          ShareParams(text: message.text),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  final chatProv = Provider.of<ChatProvider>(
                                    context,
                                    listen: false,
                                  );
                                  chatProv.sendFeedback(message, true);
                                },
                                icon: Icon(
                                  message.isLiked == true
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  size: 18,
                                ),
                                color: message.isLiked == true
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                tooltip: l10n.like,
                              ),
                              IconButton(
                                onPressed: () {
                                  final chatProv = Provider.of<ChatProvider>(
                                    context,
                                    listen: false,
                                  );
                                  chatProv.sendFeedback(message, false);
                                },
                                icon: Icon(
                                  message.isLiked == false
                                      ? Icons.thumb_down
                                      : Icons.thumb_down_outlined,
                                  size: 18,
                                ),
                                color: message.isLiked == false
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                tooltip: l10n.dislike,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInlineActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildPayloadDetails(
    Map<String, dynamic> payload,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (payload.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isComplete = !payload.values.any(
      (v) => v == null || v == "" || v == "null",
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle_outline : Icons.pending_actions,
                size: 14,
                color: isComplete ? Colors.green : Colors.amber.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                isComplete ? l10n.dataComplete : l10n.waitingForInfo,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? Colors.green : Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...payload.entries.map((entry) {
            final isMissing =
                entry.value == null ||
                entry.value == "" ||
                entry.value == "null";
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isMissing
                          ? Colors.amber.withValues(alpha: 0.5)
                          : Colors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${entry.key}: ",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: isMissing ? "Pendente" : "${entry.value}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: isMissing
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: isMissing
                                  ? Colors.amber.shade700
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
