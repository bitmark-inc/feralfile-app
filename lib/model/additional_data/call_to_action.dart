class CallToAction {
  final String? text;
  final CTATarget navigationRoute;

  CallToAction(this.text, this.navigationRoute);

  factory CallToAction.fromJson(Map<String, dynamic> json) => CallToAction(
        json['cta_text'] as String?,
        CTATarget.fromString(json['navigation_route'] as String),
      );
}

enum CTATarget {
  general,
  createPlaylistPage,
  settingsPage,
  importSeedsPage,
  globalReceivePage,
  securityPage,
  supportCustomerPage,
  supportListPage,
  bugBountyPage,
  hiddenArtworksPage,
  walletPage,
  preferencesPage,
  subscriptionPage,
  dataManagementPage,
  dailyWorkPage,
  notificationsPage;

  // toString method
  @override
  String toString() {
    switch (this) {
      case CTATarget.general:
        return 'general';
      case CTATarget.createPlaylistPage:
        return 'create_playlist_page';
      case CTATarget.settingsPage:
        return 'settings_page';
      case CTATarget.importSeedsPage:
        return 'import_seeds_page';
      case CTATarget.globalReceivePage:
        return 'global_receive_page';
      case CTATarget.securityPage:
        return 'security_page';
      case CTATarget.supportCustomerPage:
        return 'support_customer_page';
      case CTATarget.supportListPage:
        return 'support_list_page';
      case CTATarget.bugBountyPage:
        return 'bug_bounty_page';
      case CTATarget.hiddenArtworksPage:
        return 'hidden_artworks_page';
      case CTATarget.walletPage:
        return 'wallet_page';
      case CTATarget.preferencesPage:
        return 'preferences_page';
      case CTATarget.subscriptionPage:
        return 'subscription_page';
      case CTATarget.dataManagementPage:
        return 'data_management_page';
      case CTATarget.dailyWorkPage:
        return 'daily_work_page';
      case CTATarget.notificationsPage:
        return 'notifications_page';
    }
  }

  // fromString method
  static CTATarget fromString(String value) {
    switch (value) {
      case 'general':
        return CTATarget.general;
      case 'create_playlist_page':
        return CTATarget.createPlaylistPage;
      case 'settings_page':
        return CTATarget.settingsPage;
      case 'import_seeds_page':
        return CTATarget.importSeedsPage;
      case 'global_receive_page':
        return CTATarget.globalReceivePage;
      case 'security_page':
        return CTATarget.securityPage;
      case 'support_customer_page':
        return CTATarget.supportCustomerPage;
      case 'support_list_page':
        return CTATarget.supportListPage;
      case 'bug_bounty_page':
        return CTATarget.bugBountyPage;
      case 'hidden_artworks_page':
        return CTATarget.hiddenArtworksPage;
      case 'wallet_page':
        return CTATarget.walletPage;
      case 'preferences_page':
        return CTATarget.preferencesPage;
      case 'subscription_page':
        return CTATarget.subscriptionPage;
      case 'data_management_page':
        return CTATarget.dataManagementPage;
      case 'daily_work_page':
        return CTATarget.dailyWorkPage;
      case 'notifications_page':
        return CTATarget.notificationsPage;
      default:
        return CTATarget.general;
    }
  }
}
