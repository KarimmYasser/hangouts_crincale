import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/graph_controller.dart';
import '../../../controllers/manage_controller.dart';

class ManageTableWidget extends StatelessWidget {
  const ManageTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ManageController controller = Get.find();
    final GraphController graphController = Get.find();
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Manage Curves", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            // Obx rebuilds the list when curves are added or removed
            Obx(() {
              if (controller.activeCurves.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Select a model to begin."),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.activeCurves.length,
                itemBuilder: (context, index) {
                  final curve = controller.activeCurves[index];
                  return Obx(
                    () => Material(
                      color:
                          graphController.baselineCurve.value == curve
                              ? theme.colorScheme.primary.withAlpha(25)
                              : Colors.transparent,
                      child: ListTile(
                        leading: Icon(Icons.show_chart, color: curve.color),
                        title: Text('${curve.brandID} ${curve.name}'),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              icon: Icon(
                                graphController.baselineCurve.value == curve
                                    ? Icons.star
                                    : Icons.star_border,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: "Set as Baseline",
                              onPressed: () => controller.setBaseline(curve),
                            ),
                            IconButton(
                              icon: Icon(
                                curve.isVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              tooltip: "Hide/Show Curve",
                              onPressed: () => controller.hideCurve(curve.id),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[400],
                              ),
                              tooltip: "Remove Curve",
                              onPressed: () => controller.removeCurve(curve.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
