import 'package:flutter/material.dart';
import '../../services/local_guidelines_plugin.dart';
import 'setting_tile.dart';
import 'settings_section_header.dart';
import 'settings_section_spacer.dart';

/// Settings section for selecting the user's home region/city.
///
/// Shows the currently selected city and allows the user to pick from
/// all registered city plugins. The selection is used by the policy engine
/// to apply city-specific disposal rules.
class RegionSelectionSection extends StatefulWidget {
  const RegionSelectionSection({super.key});

  @override
  State<RegionSelectionSection> createState() => _RegionSelectionSectionState();
}

class _RegionSelectionSectionState extends State<RegionSelectionSection> {
  String _selectedRegion = '';

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  void _loadRegion() {
    setState(() {
      _selectedRegion = 'Bangalore, IN';
    });
  }

  List<_CityOption> _getAvailableCities() {
    final pluginIds = [
      ('bbmp_bangalore', 'Bangalore', 'BBMP'),
      ('bmc_mumbai', 'Mumbai', 'BMC'),
      ('mcd_delhi', 'Delhi', 'MCD'),
      ('pmc_pune', 'Pune', 'PMC'),
      ('ghmc_hyderabad', 'Hyderabad', 'GHMC'),
      ('gcc_chennai', 'Chennai', 'GCC'),
      ('kmc_kolkata', 'Kolkata', 'KMC'),
      ('amc_ahmedabad', 'Ahmedabad', 'AMC'),
      ('smc_surat', 'Surat', 'SMC'),
      ('jmc_jaipur', 'Jaipur', 'JMC'),
      ('lmc_lucknow', 'Lucknow', 'LMC'),
      ('nmc_nagpur', 'Nagpur', 'NMC'),
      ('imc_indore', 'Indore', 'IMC'),
      ('bmc_bhopal', 'Bhopal', 'BMC'),
      ('ccmc_coimbatore', 'Coimbatore', 'CCMC'),
      ('cochin_kochi', 'Kochi', 'Cochin Corp'),
      ('mcc_chandigarh', 'Chandigarh', 'MCC'),
    ];

    return pluginIds.map((p) {
      final plugin = LocalGuidelinesManager.getPluginForRegion(p.$1);
      return _CityOption(
        pluginId: p.$1,
        cityName: p.$2,
        authority: p.$3,
        region: plugin?.region ?? '${p.$2}, IN',
        available: plugin != null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cities = _getAvailableCities();
    final currentCity = _selectedRegion.isNotEmpty
        ? cities.where((c) => c.region == _selectedRegion).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.location_city,
          title: 'Region & Local Rules',
        ),
        SettingTile(
          icon: Icons.map,
          title: currentCity?.cityName ?? 'Set your city',
          subtitle: currentCity != null
              ? '${currentCity.authority} — ${currentCity.region}'
              : 'Select your city for local disposal rules',
          onTap: () => _showCityPicker(context, cities),
        ),
        const SettingsSectionSpacer(),
      ],
    );
  }

  void _showCityPicker(BuildContext context, List<_CityOption> cities) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select your city',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disposal rules vary by city. Choose yours\nto get accurate local guidelines.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = city.region == _selectedRegion;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(city.cityName),
                  subtitle: Text('${city.authority} — ${city.region}'),
                  trailing: city.available
                      ? null
                      : const Icon(Icons.hourglass_empty, size: 16),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedRegion = city.region;
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityOption {
  const _CityOption({
    required this.pluginId,
    required this.cityName,
    required this.authority,
    required this.region,
    required this.available,
  });

  final String pluginId;
  final String cityName;
  final String authority;
  final String region;
  final bool available;
}
