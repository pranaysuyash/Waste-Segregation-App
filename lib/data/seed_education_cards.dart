import '../models/education_card.dart';

const List<WasteEducationCard> allSeedEducationCards = [
  // ── EducationCard (story) ───────────────────────────
  WasteEducationCard(
    id: 'edu_greasy_cardboard',
    title: 'Why greasy cardboard is trash',
    body:
        'Cardboard fibers cannot separate from oil during recycling. One greasy '
        'pizza box can contaminate an entire batch. Tear off the clean top, bin '
        'the oily bottom.',
    iconName: 'restaurant',
    variant: EducationCardVariant.story,
    triggerMaterials: ['cardboard'],
    triggerSubcategories: ['paper'],
    priority: 10,
  ),
  WasteEducationCard(
    id: 'edu_battery_dropoff',
    title: 'Batteries need their own bin',
    body:
        'Batteries contain metals that start fires in trucks and landfills. One '
        'crushed lithium battery = one garbage truck fire. Take them to the '
        'drop-off box at your nearest electronics store.',
    iconName: 'warning',
    variant: EducationCardVariant.story,
    triggerCategories: ['hazardous', 'hazardous waste'],
    triggerSubcategories: ['battery'],
    priority: 5,
    extendedBody:
        'Batteries are the most common cause of fires in garbage trucks and '
        'recycling facilities worldwide. When crushed, the lithium inside '
        'reacts with air and ignites.\n\n'
        'Common battery types that need special disposal:\n'
        '- Lithium-ion (phones, laptops, power banks)\n'
        '- Alkaline (remote controls, toys)\n'
        '- Button cell (watches, hearing aids)\n'
        '- Lead-acid (cars, UPS backups)\n\n'
        'Collection points are available at most large electronics retailers, '
        'municipal waste facilities, and some supermarkets. Many cities also '
        'run quarterly household hazardous waste collection drives.',
    relatedCardIds: ['edu_ewhat_is_ewaste', 'mistake_containers_with_food'],
  ),
  WasteEducationCard(
    id: 'edu_medicine_strips',
    title: 'Medicine strips are NOT normal plastic',
    body:
        'Medicine blister packs are made of mixed materials - plastic + '
        'aluminium - that recycling plants cannot separate. They go in '
        'reject waste, not dry waste.',
    iconName: 'medical_services',
    variant: EducationCardVariant.story,
    triggerMaterials: ['medicine strip', 'blister pack', 'medicine pack'],
    triggerCategories: ['dry waste'],
    priority: 15,
  ),
  WasteEducationCard(
    id: 'edu_rinsing_matters',
    title: 'Rinse before you recycle',
    body:
        'A yogurt tub with residue spoils the whole recycling batch. A quick '
        'rinse is all it takes to keep the entire load recyclable. No soap '
        'needed - just water.',
    iconName: 'water_drop',
    variant: EducationCardVariant.story,
    triggerCategories: ['dry waste'],
    triggerSubcategories: ['plastic'],
    priority: 20,
    extendedBody:
        'Contamination is the single biggest problem in recycling. When food '
        'residue, grease, or liquid is left in containers, it can spoil entire '
        'batches of otherwise clean recyclables.\n\n'
        'Quick rinsing rules:\n'
        '- A splash of water is enough. No need for soap.\n'
        '- Use leftover dishwater to save water.\n'
        '- Crush bottles and containers after rinsing to save space.\n'
        '- Let them air dry before putting them in the bin.\n\n'
        'Items that always need rinsing: yogurt cups, jam jars, sauce bottles, '
        'canned food tins, drink cartons, takeaway containers.',
    relatedCardIds: ['mistake_containers_with_food', 'impact_plastic_savings'],
  ),
  WasteEducationCard(
    id: 'edu_ewhat_is_ewaste',
    title: 'What counts as e-waste',
    body:
        'E-waste is not just phones and laptops. Chargers, old earphones, dead '
        'power banks, broken keyboards - anything with a plug or battery. '
        'Drop these at e-waste collection points, not your regular bin.',
    iconName: 'devices',
    variant: EducationCardVariant.story,
    triggerCategories: ['e-waste', 'electronic'],
    priority: 10,
  ),

  // ── MaterialImpactCard (impact) ─────────────────────
  WasteEducationCard(
    id: 'impact_plastic_savings',
    title: 'One bottle, big difference',
    body:
        'Recycling one plastic bottle saves enough energy to run a 60W bulb for '
        '6 hours. Do that every week and it is like planting 4 trees a year.',
    iconName: 'eco',
    variant: EducationCardVariant.impact,
    triggerSubcategories: ['plastic'],
    priority: 25,
  ),
  WasteEducationCard(
    id: 'impact_compost_co2',
    title: 'Composting cuts methane',
    body:
        'Food waste rotting in landfill releases methane - 25x stronger '
        'than CO2. Composting cuts those emissions to zero and gives you '
        'free fertiliser.',
    iconName: 'compost',
    variant: EducationCardVariant.impact,
    triggerCategories: ['wet waste'],
    priority: 20,
  ),

  // ── CommonMistakeCard (mistake) ─────────────────────
  WasteEducationCard(
    id: 'mistake_containers_with_food',
    title: 'Containers with food in them',
    body:
        'Throwing a half-eaten container in dry waste contaminates everything '
        'around it. Empty, rinse, then recycle. A quick rinse takes 5 seconds.',
    iconName: 'restaurant',
    variant: EducationCardVariant.mistake,
    triggerSubcategories: ['plastic'],
    priority: 30,
  ),
  WasteEducationCard(
    id: 'mistake_wet_paper',
    title: 'Wet paper is not recyclable',
    body:
        'Wet paper fibers break down too much to be made into new paper. If '
        'it is wet or stained with food, it goes in wet waste, not dry.',
    iconName: 'water_drop',
    variant: EducationCardVariant.mistake,
    triggerSubcategories: ['paper'],
    priority: 30,
  ),
  WasteEducationCard(
    id: 'mistake_glass_ceramic',
    title: 'Not all glass is the same',
    body:
        'Glass bottles and jars? Recycle. But drinking glasses, Pyrex, and '
        'window glass melt at different temperatures - they ruin the '
        'recycling batch. Those go in reject waste.',
    iconName: 'category',
    variant: EducationCardVariant.mistake,
    triggerMaterials: ['glass'],
    priority: 30,
  ),

  // ── LocalRuleExplainer (localRule) ──────────────────
  WasteEducationCard(
    id: 'bbmp_dry_days',
    title: 'BBMP picks dry waste Mon/Wed/Fri',
    body:
        'Bangalore BBMP collects dry waste on Monday, Wednesday, and Friday. '
        'Set it out by 7 AM. On other days, the truck will not take it - '
        'and it will count as litter.',
    iconName: 'verified',
    variant: EducationCardVariant.localRule,
    triggerCategories: ['dry waste'],
    applicableRegions: ['bangalore'],
    priority: 10,
  ),
  WasteEducationCard(
    id: 'bbmp_wet_daily',
    title: 'BBMP wet waste is daily',
    body:
        'BBMP collects wet waste every day between 6-10 AM. Keep it in a '
        'closed bin to avoid attracting strays and odour.',
    iconName: 'verified',
    variant: EducationCardVariant.localRule,
    triggerCategories: ['wet waste'],
    applicableRegions: ['bangalore'],
    priority: 10,
  ),
  WasteEducationCard(
    id: 'bbmp_hazardous_kspcb',
    title: 'Hazardous waste needs KSPCB',
    body:
        'BBMP does not collect hazardous waste. Take batteries, paints, and '
        'chemicals to the KSPCB facility in Bidadi or your nearest collection '
        'drive.',
    iconName: 'warning',
    variant: EducationCardVariant.localRule,
    triggerCategories: ['hazardous', 'hazardous waste'],
    applicableRegions: ['bangalore'],
    priority: 5,
  ),

  // ── AlternativeActionCard (alternative) ─────────────
  WasteEducationCard(
    id: 'alt_old_phones',
    title: 'Do not bin that old phone',
    body:
        'Old phones contain gold, silver, and rare minerals. Drop them at an '
        'e-waste kiosk or give them to a repair shop that recycles responsibly. '
        'Some brands even offer free take-back.',
    iconName: 'hardware',
    variant: EducationCardVariant.alternative,
    triggerCategories: ['e-waste', 'electronic'],
    triggerSubcategories: ['electronic'],
    priority: 15,
  ),
  WasteEducationCard(
    id: 'alt_clothes_donate',
    title: 'Clothes are not trash',
    body:
        'Old clothes in landfill take 200+ years to break down and leak dyes '
        'into groundwater. Donate wearable items, use torn ones as rags, or '
        'find a textile recycler.',
    iconName: 'shopping_bag',
    variant: EducationCardVariant.alternative,
    triggerMaterials: ['textile'],
    triggerSubcategories: ['textile'],
    priority: 20,
  ),
];
