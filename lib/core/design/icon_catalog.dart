import 'package:flutter/material.dart';

class TimiqIconOption {
  const TimiqIconOption(this.icon, this.label);

  final IconData icon;
  final String label;
}

const timiqIconCatalog = <TimiqIconOption>[
  TimiqIconOption(Icons.work_outline_rounded, 'Práce'),
  TimiqIconOption(Icons.code_rounded, 'Vývoj'),
  TimiqIconOption(Icons.groups_outlined, 'Lidé'),
  TimiqIconOption(Icons.family_restroom_rounded, 'Rodina'),
  TimiqIconOption(Icons.rocket_launch_outlined, 'Projekt'),
  TimiqIconOption(Icons.home_outlined, 'Domov'),
  TimiqIconOption(Icons.cleaning_services_outlined, 'Úklid'),
  TimiqIconOption(Icons.restaurant_outlined, 'Jídlo'),
  TimiqIconOption(Icons.sports_esports_outlined, 'Hry'),
  TimiqIconOption(Icons.fitness_center_rounded, 'Pohyb'),
  TimiqIconOption(Icons.directions_run_rounded, 'Běh'),
  TimiqIconOption(Icons.self_improvement_rounded, 'Klid'),
  TimiqIconOption(Icons.menu_book_outlined, 'Čtení'),
  TimiqIconOption(Icons.school_outlined, 'Studium'),
  TimiqIconOption(Icons.music_note_rounded, 'Hudba'),
  TimiqIconOption(Icons.movie_outlined, 'Film'),
  TimiqIconOption(Icons.bedtime_outlined, 'Spánek'),
  TimiqIconOption(Icons.directions_car_outlined, 'Cesta'),
  TimiqIconOption(Icons.shopping_bag_outlined, 'Nákupy'),
  TimiqIconOption(Icons.favorite_outline_rounded, 'Péče'),
  TimiqIconOption(Icons.pets_outlined, 'Zvířata'),
  TimiqIconOption(Icons.lightbulb_outline_rounded, 'Tvorba'),
  TimiqIconOption(Icons.call_outlined, 'Volání'),
  TimiqIconOption(Icons.more_horiz_rounded, 'Ostatní'),
];
