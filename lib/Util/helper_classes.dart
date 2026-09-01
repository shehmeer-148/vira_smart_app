class WeekDays {
  static const int monday = 1 << 0;
  static const int tuesday = 1 << 1;
  static const int wednesday = 1 << 2;
  static const int thursday = 1 << 3;
  static const int friday = 1 << 4;
  static const int saturday = 1 << 5;
  static const int sunday = 1 << 6;

  static int mask({
    bool monday = false,
    bool tuesday = false,
    bool wednesday = false,
    bool thursday = false,
    bool friday = false,
    bool saturday = false,
    bool sunday = false,
  }) {
    int value = 0;

    if (monday) value |= WeekDays.monday;
    if (tuesday) value |= WeekDays.tuesday;
    if (wednesday) value |= WeekDays.wednesday;
    if (thursday) value |= WeekDays.thursday;
    if (friday) value |= WeekDays.friday;
    if (saturday) value |= WeekDays.saturday;
    if (sunday) value |= WeekDays.sunday;

    return value;
  }
  static bool isSelected(int mask, int index) {
    return (mask & (1 << index)) != 0;
  }

  static int toggle(int mask, int index) {
    return mask ^ (1 << index);
  }
}