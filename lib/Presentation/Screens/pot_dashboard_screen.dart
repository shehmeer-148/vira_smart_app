import 'package:flutter/material.dart';
import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../Widgets/pot_dashboard_widgets.dart';

class PotDashboardScreen extends StatefulWidget {
  final PotModel pot;
  const PotDashboardScreen({super.key, required this.pot});

  @override
  State<PotDashboardScreen> createState() => _PotDashboardScreenState();
}

class _PotDashboardScreenState extends State<PotDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.lg,
          title: Text(widget.pot.plantName, style: text.headlineSmall),
          centerTitle: true,
          // leadingWidth: 70,
          leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios))

      ),

      body: Column(
        children: [

          plantOverviewCard(widget.pot,context),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal:AppSpacing.screenHorizontal),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Expanded(child: batteryCard(widget.pot.batteryLevel,context)),

                      const SizedBox(width: 14),

                      Expanded(child: tankCard(widget.pot,context)),

                    ],
                  ),

                  const SizedBox(height: 16),

                  wateringCyclesCard(widget.pot,context),
                  const SizedBox(height: 18),

                  waterNowButton(context),

                  const SizedBox(height: 14),

                  manualWaterHint(context),

                  const SizedBox(height: 18),

                  scheduleCard(widget.pot,context),

                  const SizedBox(height: 30),

                ],
              ),
            ),
          )

        ],
      ),
    );
  }
}