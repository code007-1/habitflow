import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/habbit_card.dart';
import 'package:habbit/components/toggle_button.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/constants/selectable_icons.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_model.dart';
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
  final types = ['Binary', 'Count', 'Duration'];
  String _selectedGoalType = 'Binary';
  int _goalThreshold = 1;
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

    if (_selectedFrequency == 'Daily') _selectedDays.addAll(weekDays);

    final newHabbit = HabbitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _habbitName.trim(),
      description: _habbitDiscription.trim(),
      iconCodePoint: _selectedIcon.codePoint,
      frequency: _selectedFrequency,
      type: _selectedGoalType,
      streak: 0,
      progress: _selectedGoalType == 'Binary'
          ? '0/1 Ticks'
          : _selectedGoalType == 'Count'
          ? '0/$_goalThreshold times'
          : '0/$_goalThreshold mins',
      goalThreshold: _selectedGoalType == 'Binary' ? 1 : _goalThreshold,
      selectedDays: _selectedDays,
    );

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await DataProvider.saveData(newHabbit, DataProvider.habitsRef);
    } catch (e, st) {
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
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        onTap: (index) {
                          setState(() {
                            _selectedGoalType = types[index];
                          });
                        },
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        //indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.grey5,
                        labelStyle: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.normal,
                        ),
                        indicator: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey3,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        tabs: types.map((type) {
                          return Tab(text: type);
                        }).toList(),
                      ),
                      SizedBox(
                        height: 70,
                        child: TabBarView(
                          children: [
                            const Center(child: Text('Yes/No')),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Target Count: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                          hintText: 'e.g., 5',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _goalThreshold =
                                                int.tryParse(value) ?? 1;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Duration (mins): ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                          hintText: 'e.g., 30',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _goalThreshold =
                                                int.tryParse(value) ?? 1;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
