import 'package:flutter/material.dart';

class TimiqIconOption {
  const TimiqIconOption(this.icon, this.label);

  final IconData icon;
  final String label;
}

const timiqIconCatalog = <TimiqIconOption>[
  TimiqIconOption(Icons.work_outline_rounded, 'Práce'),
  TimiqIconOption(Icons.code_rounded, 'Vývoj'),
  TimiqIconOption(Icons.terminal_rounded, 'Terminál'),
  TimiqIconOption(Icons.memory_rounded, 'IT'),
  TimiqIconOption(Icons.smart_toy_outlined, 'AI'),
  TimiqIconOption(Icons.bug_report_outlined, 'Debug'),
  TimiqIconOption(Icons.data_object_rounded, 'Data'),
  TimiqIconOption(Icons.design_services_outlined, 'Design'),
  TimiqIconOption(Icons.handshake_outlined, 'Schůzka'),
  TimiqIconOption(Icons.video_call_outlined, 'Video hovor'),
  TimiqIconOption(Icons.email_outlined, 'E-mail'),
  TimiqIconOption(Icons.description_outlined, 'Administrativa'),
  TimiqIconOption(Icons.fact_check_outlined, 'Kontrola'),
  TimiqIconOption(Icons.calendar_month_outlined, 'Plánování'),
  TimiqIconOption(Icons.groups_outlined, 'Lidé'),
  TimiqIconOption(Icons.family_restroom_rounded, 'Rodina'),
  TimiqIconOption(Icons.child_care_outlined, 'Děti'),
  TimiqIconOption(Icons.favorite_outline_rounded, 'Péče'),
  TimiqIconOption(Icons.people_alt_outlined, 'Přátelé'),
  TimiqIconOption(Icons.rocket_launch_outlined, 'Projekt'),
  TimiqIconOption(Icons.home_outlined, 'Domov'),
  TimiqIconOption(Icons.cleaning_services_outlined, 'Úklid'),
  TimiqIconOption(Icons.yard_outlined, 'Zahrada'),
  TimiqIconOption(Icons.handyman_outlined, 'Dílna'),
  TimiqIconOption(Icons.construction_outlined, 'Nářadí'),
  TimiqIconOption(Icons.restaurant_outlined, 'Jídlo'),
  TimiqIconOption(Icons.soup_kitchen_outlined, 'Vaření'),
  TimiqIconOption(Icons.local_cafe_outlined, 'Káva'),
  TimiqIconOption(Icons.sports_esports_outlined, 'Hry'),
  TimiqIconOption(Icons.fitness_center_rounded, 'Pohyb'),
  TimiqIconOption(Icons.directions_walk_rounded, 'Chůze'),
  TimiqIconOption(Icons.directions_run_rounded, 'Běh'),
  TimiqIconOption(Icons.sports_soccer_outlined, 'Sport'),
  TimiqIconOption(Icons.monitor_heart_outlined, 'Zdraví'),
  TimiqIconOption(Icons.self_improvement_rounded, 'Klid'),
  TimiqIconOption(Icons.menu_book_outlined, 'Čtení'),
  TimiqIconOption(Icons.school_outlined, 'Studium'),
  TimiqIconOption(Icons.psychology_outlined, 'Učení'),
  TimiqIconOption(Icons.music_note_rounded, 'Hudba'),
  TimiqIconOption(Icons.movie_outlined, 'Film'),
  TimiqIconOption(Icons.live_tv_outlined, 'Televize'),
  TimiqIconOption(Icons.bedtime_outlined, 'Spánek'),
  TimiqIconOption(Icons.directions_car_outlined, 'Cesta'),
  TimiqIconOption(Icons.flight_takeoff_outlined, 'Cestování'),
  TimiqIconOption(Icons.train_outlined, 'Vlak'),
  TimiqIconOption(Icons.shopping_bag_outlined, 'Nákupy'),
  TimiqIconOption(Icons.account_balance_wallet_outlined, 'Finance'),
  TimiqIconOption(Icons.receipt_long_outlined, 'Účty'),
  TimiqIconOption(Icons.savings_outlined, 'Spoření'),
  TimiqIconOption(Icons.pets_outlined, 'Zvířata'),
  TimiqIconOption(Icons.lightbulb_outline_rounded, 'Tvorba'),
  TimiqIconOption(Icons.brush_outlined, 'Kreativita'),
  TimiqIconOption(Icons.photo_camera_outlined, 'Foto'),
  TimiqIconOption(Icons.edit_note_outlined, 'Psaní'),
  TimiqIconOption(Icons.call_outlined, 'Volání'),
  TimiqIconOption(Icons.language_outlined, 'Web'),
  TimiqIconOption(Icons.public_outlined, 'Svět'),
  TimiqIconOption(Icons.star_outline_rounded, 'Důležité'),
  TimiqIconOption(Icons.hourglass_empty_rounded, 'Čas'),
  TimiqIconOption(Icons.more_horiz_rounded, 'Ostatní'),
];

IconData timiqIconFromCodePoint(int codePoint) {
  for (final option in timiqIconCatalog) {
    if (option.icon.codePoint == codePoint) return option.icon;
  }
  final legacy = _legacyIconCodePoints[codePoint];
  if (legacy != null) return legacy;
  return Icons.more_horiz_rounded;
}

const _legacyIconCodePoints = <int, IconData>{
  // The first starter set stored these non-rounded Material icon code points.
  0xe6f4: Icons.work_outline_rounded,
  0xe257: Icons.family_restroom_rounded,
};
