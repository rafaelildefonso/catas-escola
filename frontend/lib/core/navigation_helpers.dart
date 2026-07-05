import 'package:flutter/material.dart';
import 'package:catas/core/router.dart';
import 'package:catas/providers/navigation_provider.dart';
import 'package:catas/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

AppPage getPageFromLocation(String location) {
  if (location.startsWith('/chat') || location == '/') {
    return AppPage.chat;
  }
  if (location.startsWith(AppRoutes.automations)) {
    return AppPage.automations;
  }
  if (location.startsWith(AppRoutes.integrations)) {
    return AppPage.integrations;
  }
  if (location.startsWith(AppRoutes.history)) {
    return AppPage.history;
  }
  if (location.startsWith(AppRoutes.pricing)) {
    return AppPage.pricing;
  }
  if (location.startsWith(AppRoutes.dashboard)) {
    return AppPage.dashboard;
  }
  if (location.startsWith(AppRoutes.settings)) {
    return AppPage.settings;
  }
  return AppPage.chat;
}

String getLocalizedPageTitle(BuildContext context, AppPage page) {
  final l10n = AppLocalizations.of(context)!;
  switch (page) {
    case AppPage.chat:
      return l10n.pageTitleChat;
    case AppPage.automations:
      return l10n.pageTitleAutomations;
    case AppPage.integrations:
      return l10n.pageTitleIntegrations;
    case AppPage.settings:
      return l10n.pageTitleSettings;
    case AppPage.history:
      return l10n.pageTitleHistory;
    case AppPage.pricing:
      return l10n.pageTitlePricing;
    case AppPage.dashboard:
      return l10n.pageTitleDashboard;
  }
}

String getRouteForPage(AppPage page) {
  switch (page) {
    case AppPage.chat:
      return AppRoutes.chat;
    case AppPage.automations:
      return AppRoutes.automations;
    case AppPage.integrations:
      return AppRoutes.integrations;
    case AppPage.history:
      return AppRoutes.history;
    case AppPage.pricing:
      return AppRoutes.pricing;
    case AppPage.dashboard:
      return AppRoutes.dashboard;
    case AppPage.settings:
      return AppRoutes.settings;
  }
}

AppPage getCurrentPage(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  return getPageFromLocation(location);
}
