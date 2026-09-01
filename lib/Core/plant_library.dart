// class PlantLibrary {
//   static const Map<int, String> plants = {
//     1: "Rose",
//     2: "Tulip",
//     3: "Money Plant",
//     4: "Snake Plant",
//     5: "Basil",
//     6: "Peace Lily",
//     7: "Monstera",
//     8: "ZZ Plant",
//     65535: "Custom",
//   };
//
//   static String getName(int id) {
//     return plants[id] ?? "Unknown";
//   }
// }

import '../Data/Model_classes/plant_model.dart';
import '../Util/helper_classes.dart';


class PlantLibrary {
  static final List<PlantModel> plants = [

    PlantModel(
      id: 1,
      name: "Rose",
      category: "Flowers",
      image: "images/plant_types/p1.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        tuesday: true,
        saturday: true,
      ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 2,
      name: "Tulip",
      category: "Flowers",
      image: "images/plant_types/p2.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        tuesday: true,
        saturday: true,
        friday: true
      ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 3,
      name: "Money Plant",
      category: "Indoor",
      image: "images/plant_types/p3.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        tuesday: false,
        saturday: true,
      ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 4,
      name: "Snake Plant",
      category: "Succulents",
      image: "images/plant_types/p4.png",

      wateringIntervalDays: 14,

       daysMask: WeekDays.mask(
         monday: true,
         tuesday: true,
         wednesday: true,
         friday: true,
         saturday: true,
       ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 5,
      name: "Basil",
      category: "Herbs",
      image: "images/plant_types/p5.png",
      wateringIntervalDays: 14,

     daysMask: WeekDays.mask(
       monday: true,
       tuesday: true,
       wednesday: true,
       thursday: true,
       friday: true,
       saturday: true,
       sunday: true,
     ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 6,
      name: "Peace Lily",
      category: "Indoor",
      image: "images/plant_types/p1.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(

        thursday: true,
        friday: true,
        saturday: true,
        sunday: true,
      ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 7,
      name: "Monstera",
      category: "Tropical",
      image: "images/plant_types/p3.png",
      wateringIntervalDays: 14,

       daysMask: WeekDays.mask(
         tuesday: true,
         thursday: true,
         saturday: true,
         sunday: true,
       ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 8,
      name: "ZZ Plant",
      category: "Indoor",
      image: "images/plant_types/p2.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        monday: true,
        tuesday: true,
        wednesday: true,

        sunday: true,
      ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 9,
      name: "Aloe Vera",
      category: "Succulents",
      image: "images/plant_types/p4.png",
      wateringIntervalDays: 14,

       daysMask: WeekDays.mask(

         saturday: true,
         sunday: true,
       ),
      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Aloe Vera Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 10,
      name: "Mint",
      category: "Herbs",
      image: "images/plant_types/p5.png",
      wateringIntervalDays: 14,

       daysMask: WeekDays.mask(

         wednesday: true,
         friday: true,

       ),

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Lilly prefer the soil to wet out between waterings. Default schedule is set for this.",

      popular: true,
    ),

     PlantModel(
      id: 11,
      name: "Lavender",
      category: "Flowers",
      image: "images/plant_types/p1.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        monday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        sunday: true,
      ),
      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Snake Plants like dry soil. Avoid frequent watering.",

      popular: true,
    ),

     PlantModel(
      id: 12,
      name: "Fern",
      category: "Ferns",
      image: "images/plant_types/p2.png",
      wateringIntervalDays: 14,

      daysMask: WeekDays.mask(
        monday: true,
        saturday: true,
        sunday: true,
      ),
      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip:
      "Pothos prefer the soil to dry out between waterings. Default schedule is set for this.",

      popular: true,
    ),

    const PlantModel(
      id: 0xFFFF,

      name: "Custom",

      wateringIntervalDays: 0,

      daysMask: 00000000,

      timeMinutes: 9 * 60,

      wateringsPerDay: 1,

      waterDuration: 30,

      tip: "Create your own watering schedule.",
      category: 'Unknown',
      image: 'images/plant_types/edit.png',
    ),
  ];

  static PlantModel? getById(int id) {
    try {
      return plants.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static String getName(int id) {
    return getById(id)?.name ?? "Unknown";
  }


}