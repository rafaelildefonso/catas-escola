import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../core/app_config.dart';
import '../core/router.dart';
import '../main.dart';

/// States for the demo autoplay flow.
enum DemoAutoplayState {
  idle,
  typing,
  thinking,
  responding,
  navigating,
  timelapse,
  notifying,
  reportReady,
}

/// Controller that orchestrates the entire demo autoplay sequence.
/// Manages timing, auto-typing, auto-navigation, and state transitions.
class DemoAutoplayController extends ChangeNotifier {
  DemoAutoplayState _state = DemoAutoplayState.idle;
  int _currentStep = 0;
  Timer? _stepTimer;
  String? _currentTypingText;
  int _typingIndex = 0;
  Timer? _typingTimer;
  bool _isOnboardingDemo = false;

  // Callbacks for external integration
  final List<VoidCallback> _onShowTimelapse = [];
  final List<VoidCallback> _onShowNotification = [];
  final List<VoidCallback> _onNavigateToReport = [];
  final List<VoidCallback> _onSendMessage = [];
  final List<VoidCallback> _onNavigateToAutomationDetail = [];
  // Callbacks for component interaction (componentType, componentValue)
  final List<void Function(String, String)> _onFillComponent = [];
  // Callback for clicking approve button on action_approval component
  final List<VoidCallback> _onApproveAction = [];
  // Callback for adding automation
  final List<VoidCallback> _onAddAutomation = [];
  // Callback that accepts text to send (for approval messages)
  final List<void Function(String)> _onSendText = [];

  DemoAutoplayState get state => _state;
  int get currentStep => _currentStep;
  String? get currentTypingText => _currentTypingText;
  bool get isRunning => _state != DemoAutoplayState.idle;

  // Step configuration with delays (in seconds) for each scene
  static const List<_DemoStep> _steps = [
    // Turn 1: Ask for report
    _DemoStep(
      type: DemoStepType.typeMessage,
      text: 'Quero um relatório de vendas da última semana',
      delayAfter: 0.5,
    ),
    _DemoStep(
      type: DemoStepType.sendMessage,
      delayAfter: 1.5,
    ),
    _DemoStep(
      type: DemoStepType.waitForResponse,
      delayAfter: 1.5,
    ),
    // Turn 2: Fill the text_input component
    _DemoStep(
      type: DemoStepType.fillComponent,
      componentType: 'text_input',
      componentValue: 'Vendas 2026',
      delayAfter: 1.0,
    ),
    // Wait for IA response with action_approval component
    _DemoStep(
      type: DemoStepType.waitForResponse,
      delayAfter: 2.0,
    ),
    // Turn 3: Click the approve button
    _DemoStep(
      type: DemoStepType.approveAction,
      delayAfter: 2.0,
    ),
    // Wait for confirmation
    _DemoStep(
      type: DemoStepType.waitForResponse,
      delayAfter: 2.0,
    ),
    // Add automation immediately
    _DemoStep(
      type: DemoStepType.addAutomation,
      delayAfter: 0.5,
    ),
    // Navigate to automations
    _DemoStep(
      type: DemoStepType.navigate,
      route: AppRoutes.automations,
      delayAfter: 5.0,
    ),
    _DemoStep(
      type: DemoStepType.timelapse,
      delayAfter: 4.0,
    ),
    _DemoStep(
      type: DemoStepType.showNotification,
      delayAfter: 4.0,
    ),
    _DemoStep(
      type: DemoStepType.navigate,
      route: '/report/demo',
      delayAfter: 3.0,
    ),
  ];

  static const List<_DemoStep> _onboardingSteps = [
    _DemoStep(
      type: DemoStepType.typeMessage,
      text: 'Fechamos contrato com João Silva. Organize o onboarding para sexta às 14h.',
      delayAfter: 0.5,
    ),
    _DemoStep(
      type: DemoStepType.sendMessage,
      delayAfter: 2.0,
    ),
    _DemoStep(
      type: DemoStepType.waitForResponse,
      delayAfter: 15.0,
    ),
    _DemoStep(
      type: DemoStepType.navigateAutomationDetail,
      delayAfter: 2.0,
    ),
  ];

  bool get isOnboardingDemo => _isOnboardingDemo;

  /// Starts the demo autoplay sequence (report flow).
  void startDemo() {
    if (!AppConfig.isDemoMode) {
      debugPrint('DemoAutoplayController: Cannot start - not in demo mode');
      return;
    }

    debugPrint('DemoAutoplayController: Starting report demo sequence...');
    _isOnboardingDemo = false;
    _currentStep = 0;
    _state = DemoAutoplayState.idle;
    notifyListeners();

    _advanceStep();
  }

  /// Starts the onboarding demo autoplay sequence.
  void startOnboardingDemo() {
    if (!AppConfig.isDemoMode) {
      debugPrint('DemoAutoplayController: Cannot start - not in demo mode');
      return;
    }

    debugPrint('DemoAutoplayController: Starting onboarding demo sequence...');
    _isOnboardingDemo = true;
    _currentStep = 0;
    _state = DemoAutoplayState.idle;
    notifyListeners();

    _advanceStep();
  }

  /// Stops the demo autoplay.
  void stopDemo() {
    _stepTimer?.cancel();
    _typingTimer?.cancel();
    _state = DemoAutoplayState.idle;
    _currentStep = 0;
    notifyListeners();
  }

  /// Advances to the next step in the sequence.
  void _advanceStep() {
    final steps = _isOnboardingDemo ? _onboardingSteps : _steps;
    if (_currentStep >= steps.length) {
      debugPrint('DemoAutoplayController: Demo sequence complete');
      _state = DemoAutoplayState.idle;
      notifyListeners();
      return;
    }

    final step = steps[_currentStep];
    debugPrint('DemoAutoplayController: Executing step $_currentStep: ${step.type}');
    _executeStep(step);
  }

  /// Executes a single demo step.
  Future<void> _executeStep(_DemoStep step) async {
    switch (step.type) {
      case DemoStepType.typeMessage:
        debugPrint('DemoAutoplayController: Typing message: "${step.text}"');
        _startTyping(step.text!, step.delayAfter);
        break;
      case DemoStepType.thinking:
        _setState(DemoAutoplayState.thinking);
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.waitForResponse:
        _setState(DemoAutoplayState.responding);
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.sendMessage:
        debugPrint('DemoAutoplayController: Sending message...');
        _setState(DemoAutoplayState.responding);
        await _sendCurrentMessage();
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.fillComponent:
        debugPrint('DemoAutoplayController: Filling component ${step.componentType} with "${step.componentValue}"');
        await _fillComponent(step.componentType!, step.componentValue!);
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.approveAction:
        _setState(DemoAutoplayState.responding);
        debugPrint('DemoAutoplayController: Clicking approve button');
        await _clickApproveButton();
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.navigate:
        debugPrint('DemoAutoplayController: Navigating to ${step.route}');
        _setState(DemoAutoplayState.navigating);
        _navigateToRoute(step.route!);
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.navigateAutomationDetail:
        debugPrint('DemoAutoplayController: Navigating to automation detail');
        _setState(DemoAutoplayState.navigating);
        _triggerNavigateToAutomationDetail();
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.timelapse:
        _setState(DemoAutoplayState.timelapse);
        _triggerTimelapse();
        _scheduleNextStep(step.delayAfter + 3.0);
        break;
      case DemoStepType.showNotification:
        _setState(DemoAutoplayState.notifying);
        _triggerNotification();
        _scheduleNextStep(step.delayAfter);
        break;
      case DemoStepType.addAutomation:
        _setState(DemoAutoplayState.thinking);
        debugPrint('DemoAutoplayController: Adding automation');
        _triggerAddAutomation();
        _scheduleNextStep(step.delayAfter);
        break;
    }
  }

  /// Starts the auto-typing animation for a message.
  void _startTyping(String fullText, double delayAfter) {
    _setState(DemoAutoplayState.typing);
    _currentTypingText = '';
    _typingIndex = 0;
    notifyListeners();

    // Calculate typing speed: ~30 chars per second
    final typingDuration = (fullText.length / 30.0).clamp(1.0, 5.0);
    final intervalMs = (typingDuration * 1000 / fullText.length).round();

    _typingTimer = Timer.periodic(
      Duration(milliseconds: intervalMs.clamp(20, 100)),
      (timer) {
        if (_typingIndex >= fullText.length) {
          timer.cancel();
          _currentTypingText = fullText;
          notifyListeners();
          _scheduleNextStep(delayAfter);
          return;
        }

        _typingIndex++;
        _currentTypingText = fullText.substring(0, _typingIndex);
        notifyListeners();
      },
    );
  }

  /// Schedules the next step after a delay.
  void _scheduleNextStep(double delaySeconds) {
    _stepTimer?.cancel();
    _stepTimer = Timer(
      Duration(milliseconds: (delaySeconds * 1000).round()),
      () {
        _currentStep++;
        _advanceStep();
      },
    );
  }

  /// Sets the current state and notifies listeners.
  void _setState(DemoAutoplayState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Navigates to a route using the global navigator key.
  void _navigateToRoute(String route) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route == AppRoutes.demoReport || route == AppRoutes.automations) {
          context.push(route);
        } else {
          context.go(route);
        }
      });
    }
  }

  /// Triggers the timelapse overlay.
  void _triggerTimelapse() {
    for (final callback in _onShowTimelapse) {
      callback();
    }
  }

  /// Triggers the notification.
  void _triggerNotification() {
    for (final callback in _onShowNotification) {
      callback();
    }
  }

  /// Sends the current message via the registered callback.
  Future<void> _sendCurrentMessage() async {
    for (final callback in _onSendMessage) {
      callback();
    }
  }

  /// Fills a component via the registered callback.
  Future<void> _fillComponent(String componentType, String value) async {
    for (final callback in _onFillComponent) {
      callback(componentType, value);
    }
  }

  /// Clicks the approve button via the registered callback.
  Future<void> _clickApproveButton() async {
    for (final callback in _onApproveAction) {
      callback();
    }
  }

  /// Triggers navigation to automation detail via registered callback.
  void _triggerNavigateToAutomationDetail() {
    for (final callback in _onNavigateToAutomationDetail) {
      callback();
    }
  }

  /// Registers a callback for when timelapse should be shown.
  void onShowTimelapse(VoidCallback callback) {
    _onShowTimelapse.add(callback);
  }

  /// Registers a callback for when notification should be shown.
  void onShowNotification(VoidCallback callback) {
    _onShowNotification.add(callback);
  }

  /// Registers a callback for when should navigate to report.
  void onNavigateToReport(VoidCallback callback) {
    _onNavigateToReport.add(callback);
  }

  /// Registers a callback for when message should be sent.
  void onSendMessage(VoidCallback callback) {
    _onSendMessage.add(callback);
  }

  /// Registers a callback for filling a component.
  void onFillComponent(void Function(String, String) callback) {
    _onFillComponent.add(callback);
  }

  /// Registers a callback for navigating to automation detail.
  void onNavigateToAutomationDetail(VoidCallback callback) {
    _onNavigateToAutomationDetail.add(callback);
  }

  /// Triggers the add automation callback.
  void _triggerAddAutomation() {
    for (final callback in _onAddAutomation) {
      callback();
    }
  }

  /// Registers a callback for adding automation.
  void onAddAutomation(VoidCallback callback) {
    _onAddAutomation.add(callback);
  }

  /// Registers a callback for clicking approve on action_approval component.
  void onApproveAction(VoidCallback callback) {
    _onApproveAction.add(callback);
  }

  /// Removes all registered callbacks.
  void clearCallbacks() {
    _onShowTimelapse.clear();
    _onShowNotification.clear();
    _onNavigateToReport.clear();
    _onSendMessage.clear();
    _onFillComponent.clear();
    _onApproveAction.clear();
    _onAddAutomation.clear();
    _onSendText.clear();
    _onNavigateToAutomationDetail.clear();
  }

  /// Registers a callback for when a text message should be sent.
  void onSendText(void Function(String) callback) {
    _onSendText.add(callback);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _typingTimer?.cancel();
    clearCallbacks();
    super.dispose();
  }
}

/// Types of demo steps.
enum DemoStepType {
  typeMessage,
  thinking,
  waitForResponse,
  sendMessage,
  fillComponent,
  approveAction,
  navigate,
  navigateAutomationDetail,
  timelapse,
  showNotification,
  addAutomation,
}

/// Configuration for a single demo step.
class _DemoStep {
  final DemoStepType type;
  final String? text;
  final String? route;
  final String? componentType;
  final String? componentValue;
  final double delayAfter;

  const _DemoStep({
    required this.type,
    this.text,
    this.route,
    this.componentType,
    this.componentValue,
    required this.delayAfter,
  });
}
