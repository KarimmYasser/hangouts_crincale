import 'package:flutter/material.dart';

import '../widgets/equalizer/equalizer_panel_widget.dart';
import '../widgets/graph/graph_widget.dart';
import '../widgets/manage/manage_table_widget.dart';
import '../widgets/preferences/preference_adjustments_widget.dart';
import '../widgets/selection/selection_panel_widget.dart';
import '../widgets/tools/tools_section_widget.dart';

// --- Main Screen Widget ---

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a breakpoint for switching between mobile and desktop layouts.
    const double desktopBreakpoint = 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= desktopBreakpoint) {
            // --- Desktop Layout (Wide Screen) ---
            return const _DesktopLayout();
          } else {
            // --- Mobile Layout (Narrow Screen) ---
            return const _MobileLayout();
          }
        },
      ),
    );
  }
}

// --- Layout Implementations ---

/// Desktop layout using a Row for side-by-side panels.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content on the left, takes up most of the space
        const Expanded(flex: 3, child: _MainContentWidget()),
        // Vertical divider for visual separation
        const VerticalDivider(width: 1, thickness: 1),
        // Side panel on the right for controls and EQ
        Expanded(flex: 1, child: _SidePanelWidget()),
      ],
    );
  }
}

/// Mobile layout using a TabBarView to switch between main content and controls.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    // Using a TabController to manage the two main views.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.show_chart), text: "Graph & Tools"),
              Tab(icon: Icon(Icons.tune), text: "Models & EQ"),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
          ),
          const Expanded(
            child: TabBarView(
              children: [_MainContentWidget(), _SidePanelWidget()],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Core UI Sections ---

/// Widget that contains the graph and its related tools.
/// This corresponds to the 'parts-primary' section in the HTML.
class _MainContentWidget extends StatelessWidget {
  const _MainContentWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ToolsSectionWidget(),
          const SizedBox(height: 24),
          GraphWidget(),
          const SizedBox(height: 24),
          PreferenceAdjustmentsWidget(),
          const SizedBox(height: 24),
          ManageTableWidget(),
          const SizedBox(height: 24),
          const AccessoriesWidget(),
          const SizedBox(height: 24),
          const ExternalLinksWidget(),
        ],
      ),
    );
  }
}

/// Widget for the side panel containing model selection and the equalizer.
/// This corresponds to the 'parts-secondary' section in the HTML.
class _SidePanelWidget extends StatelessWidget {
  const _SidePanelWidget();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Models'), Tab(text: 'Equalizer')]),
          Expanded(
            child: TabBarView(
              children: [SelectionPanelWidget(), EqualizerPanelWidget()],
            ),
          ),
        ],
      ),
    );
  }
}

class AccessoriesWidget extends StatelessWidget {
  const AccessoriesWidget({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // Empty for now
}

class ExternalLinksWidget extends StatelessWidget {
  const ExternalLinksWidget({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // Empty for now
}

// // --- Placeholder Widget Implementations ---
// // In a real application, each of these would be in its own file.
// // They are included here to make the MainScreen runnable and understandable.

// class GraphWidget extends StatelessWidget {
//   const GraphWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // The GraphController would be used here to get the curves
//     // final GraphController controller = Get.find();
//     return Card(
//       clipBehavior: Clip.antiAlias,
//       child: Container(
//         height: 350,
//         color: Colors.black87,
//         child: const Center(
//           child: Text(
//             'Graph would be drawn here',
//             style: TextStyle(color: Colors.white54),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ToolsSectionWidget extends StatelessWidget {
//   const ToolsSectionWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Tools", style: Theme.of(context).textTheme.titleMedium),
//             const Wrap(
//               spacing: 8.0,
//               runSpacing: 4.0,
//               children: [
//                 ElevatedButton(onPressed: null, child: Text("Zoom: Bass")),
//                 ElevatedButton(onPressed: null, child: Text("Zoom: Mids")),
//                 ElevatedButton(onPressed: null, child: Text("Zoom: Treble")),
//                 ElevatedButton(onPressed: null, child: Text("40dB Scale")),
//                 ElevatedButton(onPressed: null, child: Text("Screenshot")),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PreferenceAdjustmentsWidget extends StatelessWidget {
//   const PreferenceAdjustmentsWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Preference Adjustments",
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Tilt, Bass, Treble, and Ear Gain controls would go here.",
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ManageTableWidget extends StatelessWidget {
//   const ManageTableWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Manage Curves",
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "A table listing active headphone curves would be here.",
//             ),
//             const ListTile(
//               leading: Icon(Icons.show_chart, color: Colors.blue),
//               title: Text("Sennheiser HD 650"),
//               trailing: Icon(Icons.delete_outline),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SelectionPanelWidget extends StatelessWidget {
//   const SelectionPanelWidget({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const SingleChildScrollView(
//       padding: EdgeInsets.all(12),
//       child: Column(
//         children: [
//           TextField(
//             decoration: InputDecoration(
//               hintText: 'Search...',
//               prefixIcon: Icon(Icons.search),
//             ),
//           ),
//           SizedBox(height: 8),
//           ListTile(title: Text("Brand A"), trailing: Icon(Icons.chevron_right)),
//           ListTile(title: Text("Brand B"), trailing: Icon(Icons.chevron_right)),
//         ],
//       ),
//     );
//   }
// }

// class EqualizerPanelWidget extends StatelessWidget {
//   const EqualizerPanelWidget({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const SingleChildScrollView(
//       padding: EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Parametric Equalizer",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text("Filter, AutoEQ, and EQ Demo controls would be here."),
//         ],
//       ),
//     );
//   }
// }
