import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/habbit_card.dart';
import 'package:habbit/components/toggle_button.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/constants/selectable_icons.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/models/unit_of_measure.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class AddHabbit extends StatefulWidget {
  const AddHabbit({super.key});

  @override
  State<AddHabbit> createState() => _AddHabbitState();
}

class _AddHabbitState extends State<AddHabbit> {
  IconData _selectedIcon = Icons.water_drop_rounded;
  String _habbitName = '';
  String _habbitDiscription = '';
  String _selectedFrequency = 'Daily';
  final frequencies = ['Daily', 'Weekly', 'Custom'];

  // Unit-of-measure goal configuration.
  Dimension _selectedDimension = Units.binary;
  Unit? _selectedUnit;
  double _goalValue = 1;
  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<String> _selectedDays = [];

  void _saveHabbit(BuildContext context) async {
    if (_habbitName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isBinary = _selectedDimension == Units.binary;
    if (!isBinary && _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a unit for the goal'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFrequency == 'Daily') _selectedDays.addAll(weekDays);

    final goal = isBinary
        ? Measurement(1, Units.done)
        : Measurement(_goalValue, _selectedUnit!);

    final newHabbit = HabbitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: DataProvider.currentUserId,
      name: _habbitName.trim(),
      description: _habbitDiscription.trim(),
      icon: _selectedIcon.codePoint,
      intervalFrequency: _selectedFrequency,
      dimensionId: _selectedDimension.id,
      goalValue: goal.value,
      unitId: goal.unit.id,
      streak: 0,
      progress: isBinary ? '0/1 Ticks' : '0/${goal.format()}',
      selectedDays: _selectedDays,
    );

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await DataProvider.saveData(newHabbit, DataProvider.habitsRef);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('"${newHabbit.name}" created successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          child: Container(
            margin: EdgeInsets.all(4.0),
            padding: EdgeInsets.all(6.0),
            child: Icon(
              Icons.chevron_left_outlined,
              color: AppColors.grey7,
              size: 26,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add New Habbit',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(width: 2.0, color: AppColors.grey7),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Icon(Icons.question_mark_rounded, color: AppColors.grey7),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(10.0),
          child: Divider(color: AppColors.grey3),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Text(
                  'Habbit Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., Drink Water',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _habbitName = value;
                    });
                  },
                ),
                const Text(
                  'Habbit Description',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., Drink 2 lits of water',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _habbitDiscription = value;
                    });
                  },
                ),
                const Text(
                  'Icon & Color',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectable_icons.length,
                    itemBuilder: (context, index) {
                      final icon = selectable_icons[index];
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 56,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              width: isSelected ? 2 : 1,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey3,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey6,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Text(
                  'Goal Configuration',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                // Pick what the habit is measured in.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Units.dimensions.map((d) {
                    final selected = _selectedDimension == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedDimension = d;
                          _selectedUnit = d == Units.binary
                              ? null
                              : Units.forDimension(d).first;
                          _goalValue = 1;
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      showCheckmark: false,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.grey3,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.grey7,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                // Non-binary habits need a target amount and a unit.
                if (_selectedDimension != Units.binary)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            hintText: 'Target (e.g. 5)',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _goalValue = double.tryParse(value) ?? 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<Unit>(
                          // Rebuild the field when the dimension changes so it
                          // adopts the new unit list and default selection.
                          key: ValueKey(_selectedDimension.id),
                          initialValue: _selectedUnit,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                          ),
                          items: Units.forDimension(_selectedDimension)
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    "${u.name}${u.symbol.isNotEmpty ? " (${u.symbol})" : ''}",
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (u) => setState(() => _selectedUnit = u),
                        ),
                      ),
                    ],
                  ),
                const Text(
                  'Interval Frequency',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                MultiSelectButtons(
                  options: frequencies,
                  onOptionSelected: (index) {
                    setState(() {
                      _selectedFrequency = frequencies[index];
                    });
                  },
                ),
                if (_selectedFrequency == 'Weekly' ||
                    _selectedFrequency == 'Custom') ...[
                  const Text(
                    'Select Days',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: weekDays.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (_selectedFrequency == 'Weekly') {
                              _selectedDays.clear();
                              _selectedDays.add(day);
                            } else {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.grey3,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey7,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                HabbitCard(
                  frequency: _selectedFrequency.isEmpty
                      ? "Not Set"
                      : _selectedFrequency,
                  icon: _selectedIcon,
                  progress: "52 Ticks",
                  title: _habbitName.isEmpty ? "Some Habbit" : _habbitName,
                ),
                Builder(
                  builder: (context) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _saveHabbit(context),
                        child: Text(
                          "Create Habbit",
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(color: AppColors.grey1),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
