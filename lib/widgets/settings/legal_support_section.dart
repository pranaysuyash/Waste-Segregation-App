import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/screens/legal_document_screen.dart';
import 'package:waste_segregation_app/utils/app_version.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';

class LegalSupportSection extends StatelessWidget {
const LegalSupportSection({super.key});

@override
Widget build(BuildContext context) {
final t = AppLocalizations.of(context)!;
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SettingsSectionHeader(title: t.legalSupportSection),
SettingTile(
icon: Icons.privacy_tip,
iconColor: SettingsTheme.legalColor,
title: t.privacyPolicy,
subtitle: t.privacyPolicySubtitle,
onTap: () => _navigateToLegalDocument(
context,
t.privacyPolicy,
'assets/docs/privacy_policy.md',
),
),
SettingTile(
icon: Icons.description,
iconColor: SettingsTheme.legalColor,
title: t.termsOfService,
subtitle: t.termsOfServiceSubtitle,
onTap: () => _navigateToLegalDocument(
context,
t.termsOfService,
'assets/docs/terms_of_service.md',
),
),
SettingTile(
icon: Icons.help,
iconColor: Colors.blue,
title: t.helpSupport,
subtitle: t.helpSupportSubtitle,
onTap: () => _showSupportOptions(context),
),
SettingTile(
icon: Icons.info_outline,
iconColor: Colors.indigo,
title: t.about,
subtitle: t.aboutSubtitle,
onTap: () => _showAboutDialog(context),
),
],
);
}

void _navigateToLegalDocument(
BuildContext context,
String title,
String assetPath,
) {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => LegalDocumentScreen(
title: title,
assetPath: assetPath,
),
),
);
}

void _showSupportOptions(BuildContext context) {
showModalBottomSheet(
context: context,
builder: (BuildContext context) {
final t = AppLocalizations.of(context)!;
return Container(
padding: const EdgeInsets.all(16),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
t.helpSupport,
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 16),
ListTile(
leading: const Icon(Icons.email, color: Colors.blue),
title: Text(t.contactSupport),
subtitle: Text(t.contactSupportSubtitle),
onTap: () {
Navigator.pop(context);
_contactSupport(context);
},
),
ListTile(
leading: const Icon(Icons.bug_report, color: Colors.orange),
title: Text(t.reportBug),
subtitle: Text(t.reportBugSubtitle),
onTap: () {
Navigator.pop(context);
_reportBug(context);
},
),
ListTile(
leading: const Icon(Icons.star, color: Colors.amber),
title: Text(t.rateApp),
subtitle: Text(t.rateAppSubtitle),
onTap: () {
Navigator.pop(context);
_rateApp(context);
},
),
const SizedBox(height: 16),
],
),
);
},
);
}

void _showAboutDialog(BuildContext context) {
final t = AppLocalizations.of(context)!;
showAboutDialog(
context: context,
applicationName: t.appName,
applicationVersion: AppVersion.displayVersion,
applicationIcon: const Icon(
Icons.recycling,
size: 48,
color: Colors.green,
),
children: [
Text(t.aboutDialogBodyLine1),
const SizedBox(height: 16),
Text(t.aboutDialogBodyLine2),
],
);
}

Future<void> _contactSupport(BuildContext context) async {
try {
final packageInfo = await PackageInfo.fromPlatform();
final appVersion = packageInfo.version;
final buildNumber = packageInfo.buildNumber;

final subject =
Uri.encodeComponent('ReLoop - Support Request');
final body = Uri.encodeComponent('Hi Support Team,\n\n'
'I need help with the ReLoop.\n\n'
'App Version: $appVersion ($buildNumber)\n'
'Platform: ${Platform.operatingSystem}\n'
'Device: ${Platform.operatingSystemVersion}\n\n'
'Please describe your issue below:\n\n');

final emailUrl =
'mailto:support@reloop.app?subject=$subject&body=$body';
final uri = Uri.parse(emailUrl);

if (await canLaunchUrl(uri)) {
await launchUrl(uri);
} else {
if (context.mounted) {
_showEmailFallback(context, 'support@reloop.app');
}
}
} catch (e) {
if (context.mounted) {
final t = AppLocalizations.of(context)!;
SettingsTheme.showErrorSnackBar(
context,
t.errorOpeningEmail(e.toString()),
);
}
}
}

Future<void> _reportBug(BuildContext context) async {
try {
final packageInfo = await PackageInfo.fromPlatform();
final appVersion = packageInfo.version;
final buildNumber = packageInfo.buildNumber;

final subject = Uri.encodeComponent('ReLoop - Bug Report');
final body = Uri.encodeComponent('Hi Development Team,\n\n'
'I found a bug in the ReLoop.\n\n'
'App Version: $appVersion ($buildNumber)\n'
'Platform: ${Platform.operatingSystem}\n'
'Device: ${Platform.operatingSystemVersion}\n\n'
'Bug Description:\n'
'- What happened?\n'
'- What did you expect to happen?\n'
'- Steps to reproduce:\n'
'  1. \n'
'  2. \n'
'  3. \n\n'
'Additional Information:\n'
'- Screenshots (if applicable): \n'
'- Frequency: Always / Sometimes / Once\n\n');

final emailUrl = 'mailto:bugs@reloop.app?subject=$subject&body=$body';
final uri = Uri.parse(emailUrl);

if (await canLaunchUrl(uri)) {
await launchUrl(uri);
} else {
if (context.mounted) {
_showEmailFallback(context, 'bugs@reloop.app');
}
}
} catch (e) {
if (context.mounted) {
final t = AppLocalizations.of(context)!;
SettingsTheme.showErrorSnackBar(
context,
t.errorOpeningEmail(e.toString()),
);
}
}
}

Future<void> _rateApp(BuildContext context) async {
try {
String storeUrl;
if (Platform.isIOS) {
storeUrl =
'https://apps.apple.com/app/waste-segregation-app/id123456789';
} else if (Platform.isAndroid) {
storeUrl =
'https://play.google.com/store/apps/details?id=com.wastewise.app';
} else {
storeUrl = 'https://reloop.app';
}

final uri = Uri.parse(storeUrl);

if (await canLaunchUrl(uri)) {
await launchUrl(uri, mode: LaunchMode.externalApplication);
} else {
if (context.mounted) {
final t = AppLocalizations.of(context)!;
SettingsTheme.showInfoSnackBar(
context,
t.unableToOpenAppStore,
);
}
}
} catch (e) {
if (context.mounted) {
final t = AppLocalizations.of(context)!;
SettingsTheme.showErrorSnackBar(
context,
t.errorOpeningAppStore(e.toString()),
);
}
}
}

void _showEmailFallback(BuildContext context, String email) {
final t = AppLocalizations.of(context)!;
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text(t.emailNotAvailable),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(t.noEmailAppFound),
const SizedBox(height: 8),
SelectableText(
email,
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Colors.blue,
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: ElevatedButton.icon(
onPressed: () {
Clipboard.setData(ClipboardData(text: email));
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(t.emailAddressCopied)),
);
},
icon: const Icon(Icons.copy),
label: Text(t.copyEmail),
),
),
],
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text(t.close),
),
],
),
);
}
}
