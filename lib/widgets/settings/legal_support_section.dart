     1|import 'dart:io';
     2|
     3|import 'package:flutter/material.dart';
     4|import 'package:flutter/services.dart';
     5|import 'package:package_info_plus/package_info_plus.dart';
     6|import 'package:url_launcher/url_launcher.dart';
     7|import 'package:waste_segregation_app/l10n/app_localizations.dart';
     8|import 'package:waste_segregation_app/screens/legal_document_screen.dart';
     9|import 'package:waste_segregation_app/utils/app_version.dart';
    10|import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
    11|import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';
    12|
    13|class LegalSupportSection extends StatelessWidget {
    14|  const LegalSupportSection({super.key});
    15|
    16|  @override
    17|  Widget build(BuildContext context) {
    18|    final t = AppLocalizations.of(context)!;
    19|    return Column(
    20|      crossAxisAlignment: CrossAxisAlignment.start,
    21|      children: [
    22|        SettingsSectionHeader(title: t.legalSupportSection),
    23|        SettingTile(
    24|          icon: Icons.privacy_tip,
    25|          iconColor: SettingsTheme.legalColor,
    26|          title: t.privacyPolicy,
    27|          subtitle: t.privacyPolicySubtitle,
    28|          onTap: () => _navigateToLegalDocument(
    29|            context,
    30|            t.privacyPolicy,
    31|            'assets/docs/privacy_policy.md',
    32|          ),
    33|        ),
    34|        SettingTile(
    35|          icon: Icons.description,
    36|          iconColor: SettingsTheme.legalColor,
    37|          title: t.termsOfService,
    38|          subtitle: t.termsOfServiceSubtitle,
    39|          onTap: () => _navigateToLegalDocument(
    40|            context,
    41|            t.termsOfService,
    42|            'assets/docs/terms_of_service.md',
    43|          ),
    44|        ),
    45|        SettingTile(
    46|          icon: Icons.help,
    47|          iconColor: Colors.blue,
    48|          title: t.helpSupport,
    49|          subtitle: t.helpSupportSubtitle,
    50|          onTap: () => _showSupportOptions(context),
    51|        ),
    52|        SettingTile(
    53|          icon: Icons.info_outline,
    54|          iconColor: Colors.indigo,
    55|          title: t.about,
    56|          subtitle: t.aboutSubtitle,
    57|          onTap: () => _showAboutDialog(context),
    58|        ),
    59|      ],
    60|    );
    61|  }
    62|
    63|  void _navigateToLegalDocument(
    64|    BuildContext context,
    65|    String title,
    66|    String assetPath,
    67|  ) {
    68|    Navigator.push(
    69|      context,
    70|      MaterialPageRoute(
    71|        builder: (context) => LegalDocumentScreen(
    72|          title: title,
    73|          assetPath: assetPath,
    74|        ),
    75|      ),
    76|    );
    77|  }
    78|
    79|  void _showSupportOptions(BuildContext context) {
    80|    showModalBottomSheet(
    81|      context: context,
    82|      builder: (BuildContext context) {
    83|        final t = AppLocalizations.of(context)!;
    84|        return Container(
    85|          padding: const EdgeInsets.all(16),
    86|          child: Column(
    87|            mainAxisSize: MainAxisSize.min,
    88|            crossAxisAlignment: CrossAxisAlignment.start,
    89|            children: [
    90|              Text(
    91|                t.helpSupport,
    92|                style: Theme.of(context).textTheme.titleLarge?.copyWith(
    93|                      fontWeight: FontWeight.bold,
    94|                    ),
    95|              ),
    96|              const SizedBox(height: 16),
    97|              ListTile(
    98|                leading: const Icon(Icons.email, color: Colors.blue),
    99|                title: Text(t.contactSupport),
   100|                subtitle: Text(t.contactSupportSubtitle),
   101|                onTap: () {
   102|                  Navigator.pop(context);
   103|                  _contactSupport(context);
   104|                },
   105|              ),
   106|              ListTile(
   107|                leading: const Icon(Icons.bug_report, color: Colors.orange),
   108|                title: Text(t.reportBug),
   109|                subtitle: Text(t.reportBugSubtitle),
   110|                onTap: () {
   111|                  Navigator.pop(context);
   112|                  _reportBug(context);
   113|                },
   114|              ),
   115|              ListTile(
   116|                leading: const Icon(Icons.star, color: Colors.amber),
   117|                title: Text(t.rateApp),
   118|                subtitle: Text(t.rateAppSubtitle),
   119|                onTap: () {
   120|                  Navigator.pop(context);
   121|                  _rateApp(context);
   122|                },
   123|              ),
   124|              const SizedBox(height: 16),
   125|            ],
   126|          ),
   127|        );
   128|      },
   129|    );
   130|  }
   131|
   132|  void _showAboutDialog(BuildContext context) {
   133|    final t = AppLocalizations.of(context)!;
   134|    showAboutDialog(
   135|      context: context,
   136|      applicationName: t.appName,
   137|      applicationVersion: AppVersion.displayVersion,
   138|      applicationIcon: const Icon(
   139|        Icons.recycling,
   140|        size: 48,
   141|        color: Colors.green,
   142|      ),
   143|      children: [
   144|        Text(t.aboutDialogBodyLine1),
   145|        const SizedBox(height: 16),
   146|        Text(t.aboutDialogBodyLine2),
   147|      ],
   148|    );
   149|  }
   150|
   151|  Future<void> _contactSupport(BuildContext context) async {
   152|    try {
   153|      final packageInfo = await PackageInfo.fromPlatform();
   154|      final appVersion = packageInfo.version;
   155|      final buildNumber = packageInfo.buildNumber;
   156|
   157|      final subject =
   158|          Uri.encodeComponent('ReLoop - Support Request');
   159|      final body = Uri.encodeComponent('Hi Support Team,\n\n'
   160|          'I need help with the ReLoop.\n\n'
   161|          'App Version: $appVersion ($buildNumber)\n'
   162|          'Platform: ${Platform.operatingSystem}\n'
   163|          'Device: ${Platform.operatingSystemVersion}\n\n'
   164|          'Please describe your issue below:\n\n');
   165|
   166|      final emailUrl =
   167|          'mailto:support@reloop.app?subject=$subject&body=$body';
   168|      final uri = Uri.parse(emailUrl);
   169|
   170|      if (await canLaunchUrl(uri)) {
   171|        await launchUrl(uri);
   172|      } else {
   173|        if (context.mounted) {
   174|          _showEmailFallback(context, 'support@reloop.app');
   175|        }
   176|      }
   177|    } catch (e) {
   178|      if (context.mounted) {
   179|        final t = AppLocalizations.of(context)!;
   180|        SettingsTheme.showErrorSnackBar(
   181|          context,
   182|          t.errorOpeningEmail(e.toString()),
   183|        );
   184|      }
   185|    }
   186|  }
   187|
   188|  Future<void> _reportBug(BuildContext context) async {
   189|    try {
   190|      final packageInfo = await PackageInfo.fromPlatform();
   191|      final appVersion = packageInfo.version;
   192|      final buildNumber = packageInfo.buildNumber;
   193|
   194|      final subject = Uri.encodeComponent('ReLoop - Bug Report');
   195|      final body = Uri.encodeComponent('Hi Development Team,\n\n'
   196|          'I found a bug in the ReLoop.\n\n'
   197|          'App Version: $appVersion ($buildNumber)\n'
   198|          'Platform: ${Platform.operatingSystem}\n'
   199|          'Device: ${Platform.operatingSystemVersion}\n\n'
   200|          'Bug Description:\n'
   201|          '- What happened?\n'
   202|          '- What did you expect to happen?\n'
   203|          '- Steps to reproduce:\n'
   204|          '  1. \n'
   205|          '  2. \n'
   206|          '  3. \n\n'
   207|          'Additional Information:\n'
   208|          '- Screenshots (if applicable): \n'
   209|          '- Frequency: Always / Sometimes / Once\n\n');
   210|
   211|      final emailUrl = 'mailto:bugs@reloop.app?subject=$subject&body=$body';
   212|      final uri = Uri.parse(emailUrl);
   213|
   214|      if (await canLaunchUrl(uri)) {
   215|        await launchUrl(uri);
   216|      } else {
   217|        if (context.mounted) {
   218|          _showEmailFallback(context, 'bugs@reloop.app');
   219|        }
   220|      }
   221|    } catch (e) {
   222|      if (context.mounted) {
   223|        final t = AppLocalizations.of(context)!;
   224|        SettingsTheme.showErrorSnackBar(
   225|          context,
   226|          t.errorOpeningEmail(e.toString()),
   227|        );
   228|      }
   229|    }
   230|  }
   231|
   232|  Future<void> _rateApp(BuildContext context) async {
   233|    try {
   234|      String storeUrl;
   235|      if (Platform.isIOS) {
   236|        storeUrl =
   237|            'https://apps.apple.com/app/waste-segregation-app/id123456789';
   238|      } else if (Platform.isAndroid) {
   239|        storeUrl =
   240|            'https://play.google.com/store/apps/details?id=com.wastewise.app';
   241|      } else {
   242|        storeUrl = 'https://reloop.app';
   243|      }
   244|
   245|      final uri = Uri.parse(storeUrl);
   246|
   247|      if (await canLaunchUrl(uri)) {
   248|        await launchUrl(uri, mode: LaunchMode.externalApplication);
   249|      } else {
   250|        if (context.mounted) {
   251|          final t = AppLocalizations.of(context)!;
   252|          SettingsTheme.showInfoSnackBar(
   253|            context,
   254|            t.unableToOpenAppStore,
   255|          );
   256|        }
   257|      }
   258|    } catch (e) {
   259|      if (context.mounted) {
   260|        final t = AppLocalizations.of(context)!;
   261|        SettingsTheme.showErrorSnackBar(
   262|          context,
   263|          t.errorOpeningAppStore(e.toString()),
   264|        );
   265|      }
   266|    }
   267|  }
   268|
   269|  void _showEmailFallback(BuildContext context, String email) {
   270|    final t = AppLocalizations.of(context)!;
   271|    showDialog(
   272|      context: context,
   273|      builder: (context) => AlertDialog(
   274|        title: Text(t.emailNotAvailable),
   275|        content: Column(
   276|          mainAxisSize: MainAxisSize.min,
   277|          crossAxisAlignment: CrossAxisAlignment.start,
   278|          children: [
   279|            Text(t.noEmailAppFound),
   280|            const SizedBox(height: 8),
   281|            SelectableText(
   282|              email,
   283|              style: const TextStyle(
   284|                fontWeight: FontWeight.bold,
   285|                color: Colors.blue,
   286|              ),
   287|            ),
   288|            const SizedBox(height: 16),
   289|            Row(
   290|              children: [
   291|                Expanded(
   292|                  child: ElevatedButton.icon(
   293|                    onPressed: () {
   294|                      Clipboard.setData(ClipboardData(text: email));
   295|                      Navigator.pop(context);
   296|                      ScaffoldMessenger.of(context).showSnackBar(
   297|                        SnackBar(content: Text(t.emailAddressCopied)),
   298|                      );
   299|                    },
   300|                    icon: const Icon(Icons.copy),
   301|                    label: Text(t.copyEmail),
   302|                  ),
   303|                ),
   304|              ],
   305|            ),
   306|          ],
   307|        ),
   308|        actions: [
   309|          TextButton(
   310|            onPressed: () => Navigator.pop(context),
   311|            child: Text(t.close),
   312|          ),
   313|        ],
   314|      ),
   315|    );
   316|  }
   317|}
   318|