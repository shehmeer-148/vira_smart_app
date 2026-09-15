import 'package:flutter/material.dart';
import 'package:vira_planter_app/Presentation/Screens/schedule_builder_screen.dart';
import 'package:vira_planter_app/Util/app_snackbar.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';

// class ChoosePlantScreen extends StatefulWidget {
//   const ChoosePlantScreen({super.key});
//
//   @override
//   State<ChoosePlantScreen> createState() => _ChoosePlantScreenState();
// }
//
// class _ChoosePlantScreenState extends State<ChoosePlantScreen> {
//   final TextEditingController _searchController = TextEditingController();
//
//   int selectedCategory = 0;
//
//   final categories = [
//     "All",
//     "Tropical",
//     "Succulents",
//     "Herbs",
//     "Ferns",
//   ];
//
//
//   @override
//   Widget build(BuildContext context) {
//     final text = Theme.of(context).textTheme;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         titleSpacing: AppSpacing.lg,
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 "Choose Your Plant",
//                 style: text.headlineSmall,
//               ),
//             ),
//             Text(
//               "Step 1 of 3",
//               style: text.bodySmall?.copyWith(color: AppColors.primary.withOpacity(.6)),
//             )
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.screenHorizontal,
//         ),
//         child: Column(
//           children: [
//             const SizedBox(height: 10),
//
//             _searchField(),
//
//             const SizedBox(height: 18),
//
//             _categoryList(),
//
//             const SizedBox(height: 18),
//
//             Expanded(
//               child: GridView.builder(
//                 itemCount: plants.length,
//                 physics: const BouncingScrollPhysics(),
//                 gridDelegate:
//                 const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 14,
//                   mainAxisSpacing: 14,
//                   childAspectRatio: 1,
//                 ),
//                 itemBuilder: (_, index) {
//                   final plant = plants[index];
//
//                   return _plantCard(
//                     image: plant["image"] as String,
//                     name: plant["name"] as String,
//                     subtitle: plant["days"] as String,
//                     popular: plant["popular"] as bool,
//                   );
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _searchField() {
//     return TextField(
//       controller: _searchController,
//       decoration: InputDecoration(
//         hintText: "Search plants...",
//         prefixIcon: Icon(Icons.search),
//         hintStyle: TextTheme.of(context).labelLarge?.copyWith(color: AppColors.textHint),
//       ),
//       style: TextTheme.of(context).labelLarge,
//     );
//   }
//
//   Widget _categoryList() {
//     return SizedBox(
//       height: 35,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: categories.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 10),
//         itemBuilder: (_, index) {
//           final selected = selectedCategory == index;
//
//           return InkWell(
//             borderRadius: BorderRadius.circular(30),
//             onTap: () {
//               setState(() {
//                 selectedCategory = index;
//               });
//             },
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//               ),
//               decoration: BoxDecoration(
//                 color: selected
//                     ? AppColors.primary
//                     : Colors.white,
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               child: Center(
//                 child: Text(
//                   categories[index],
//                   style: Theme.of(context)
//                       .textTheme
//                       .labelLarge
//                       ?.copyWith(
//                     color: selected
//                         ? Colors.white
//                         : AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _plantCard({
//     required String image,
//     required String name,
//     required String subtitle,
//     bool popular = false,
//   }) {
//     final text = Theme.of(context).textTheme;
//
//     return Material(
//       elevation: 2,
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: () {
//           Navigator.push(context, MaterialPageRoute(builder: (context)=>WateringScheduleScreen()));
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     height: 46,
//                     width: 46,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(.12),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Image.asset(image),
//                     ),
//                   ),
//                   const Spacer(),
//                   if (popular)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 3,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.accentLight.withOpacity(.35),
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Text(
//                         "POP",
//                         style: text.labelSmall?.copyWith(
//                           color: AppColors.accentDark,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     )
//                 ],
//               ),
//
//               const Spacer(),
//
//               Text(
//                 name,
//                 style: text.titleMedium,
//                 maxLines: 1,
//               ),
//
//               const SizedBox(height: 2),
//
//               Text(
//                 subtitle,
//                 style: text.bodyMedium,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:provider/provider.dart';
import '../../Data/Model_classes/plant_model.dart';
import '../Providers/ble_provider.dart';
import '../Providers/plant_provider.dart';

class ChoosePlantScreen extends StatefulWidget {
  const ChoosePlantScreen({super.key});

  @override
  State<ChoosePlantScreen> createState() => _ChoosePlantScreenState();
}

class _ChoosePlantScreenState extends State<ChoosePlantScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PlantProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Choose Your Plant",
                style: text.headlineSmall,
              ),
            ),
            Text(
              "Step 1 of 3",
              style: text.bodySmall?.copyWith(
                color: AppColors.primary.withOpacity(.6),
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Column(
          children: [

            const SizedBox(height: 10),

            //-----------------------------------
            // SEARCH
            //-----------------------------------

            TextField(
              controller: searchController,
              onChanged: provider.searchPlant,
              style: text.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: "Search plants...",
                prefixIcon: const Icon(Icons.search),
                hintStyle: text.labelLarge?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),

            const SizedBox(height: 18),

            //-----------------------------------
            // CATEGORY
            //-----------------------------------

            SizedBox(
              height: 35,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),

                itemBuilder: (_, index) {

                  final selected =
                      provider.selectedCategory == index;

                  return InkWell(

                    borderRadius:
                    BorderRadius.circular(30),

                    onTap: () {
                      provider.changeCategory(index);
                    },

                    child: AnimatedContainer(

                      duration:
                      const Duration(milliseconds: 250),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),

                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(30),
                      ),

                      child: Center(
                        child: Text(
                          provider.categories[index],
                          style: text.labelLarge?.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            //-----------------------------------
            // GRID
            //-----------------------------------

            Expanded(
              child: GridView.builder(

                physics:
                const BouncingScrollPhysics(),

                itemCount: provider.filteredPlants.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),

                itemBuilder: (_, index) {

                  final plant =
                  provider.filteredPlants[index];

                  return _PlantCard(
                    plant: plant,
                  );
                },
              ),
            ),

            //-----------------------------------
            // CONTINUE
            //-----------------------------------

            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(

                    onPressed:
                    provider.selectedPlant == null
                        ? null
                        : () async {

                      final plantProvider =
                      context.read<PlantProvider>();

                      final bleProvider =
                      context.read<BleProvider>();

                      if (plantProvider.selectedPlant == null) {
                        AppSnackbar.success(context, "Please Select a Plant First");
                        return;
                      }

                      final plant = plantProvider.selectedPlant!;


                      final success = await bleProvider.saveSelectedPlant(
                        plantId: plant.id,
                        plantName: plant.name,
                      );

                      if (!context.mounted) return;

                      if (success) {
                       // print("🟢 CONNECTED — STARTING VIRA READ TEST");


                        // await bleProvider.setupDone();
                        // final plantName = await bleProvider.readPlantName();
                        // final plantType= await bleProvider.readPlantType();
                        // final batteryLevel = await bleProvider.readBatteryLevel();
                        // await bleProvider.readDeviceUuid();
                        // bleProvider.startBatteryNotification();
                        // print("");
                        // print("==========================================");
                        // print("✅ VIRA READ TEST RESULT");
                        // print("Battery Level : $batteryLevel");
                        // print("Plant Name : $plantName");
                        // print("Plant Type : $plantType");
                        // print("==========================================");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WateringScheduleScreen(),
                          ),
                        );
                      }
                      else{
                        AppSnackbar.error(context, "Vira Pot disconnected!");
                      }
                    },

                  child: const Text("Continue"),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}

class _PlantCard extends StatelessWidget {

  final PlantModel plant;

  const _PlantCard({
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PlantProvider>();

    final selected =
        provider.selectedPlant?.id == plant.id;

    final text = Theme.of(context).textTheme;

    return Material(

      elevation: selected ? 6 : 2,

      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(

        borderRadius: BorderRadius.circular(20),

        onTap: () {
          provider.selectPlant(plant);
        },

        child: AnimatedContainer(

          duration:
          const Duration(milliseconds: 250),

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(

            borderRadius:
            BorderRadius.circular(20),

            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  Container(
                    height: 46,
                    width: 46,

                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(.12),

                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Padding(
                      padding:
                      const EdgeInsets.all(8),

                      child: Image.asset(
                        plant.image,
                      ),
                    ),
                  ),

                  const Spacer(),

                  if (plant.popular)

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),

                      decoration: BoxDecoration(
                        color: AppColors.accentLight
                            .withOpacity(.35),

                        borderRadius:
                        BorderRadius.circular(30),
                      ),

                      child: Text(
                        "POP",
                        style: text.labelSmall?.copyWith(
                          color:
                          AppColors.accentDark,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              Text(
                plant.name,
                style: text.titleMedium,
                maxLines: 1,
              ),

              const SizedBox(height: 2),

              Text(
                plant.subtitle,
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}