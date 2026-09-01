import 'package:flutter/material.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../Widgets/setting_widgets.dart';

class SettingScreen extends StatefulWidget {
  final PotModel pot;
  const SettingScreen({super.key, required this.pot});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  TextEditingController plantNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.lg,
          title: Text("Pot Settings", style: text.headlineSmall),
          centerTitle: true,
          // leadingWidth: 70,
          leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios))
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
         horizontal:  AppSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            plantInfoCard(context,widget.pot,plantNameController),

            const SizedBox(height: 22),

            sectionTitle("Schedule",context),

            const SizedBox(height: 10),

            scheduleCard(widget.pot,context),

            const SizedBox(height: 22),

            sectionTitle("Connectivity",context),

            const SizedBox(height: 10),

            connectivityCard(context),

            const SizedBox(height: 22),

            sectionTitle("Device",context),

            const SizedBox(height: 10),

            deviceInfoCard(widget.pot, context),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }


}
