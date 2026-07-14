import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/habbit_history_list.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogHabbit extends StatefulWidget {
  final HabbitModel habbit;

  const LogHabbit({super.key, required this.habbit});

  @override
  State<LogHabbit> createState() => _LogHabbitState();
}

class _LogHabbitState extends State<LogHabbit> {
  String _inputValue = '';
  String _noteValue = '';
  HabbitModel? _currentHabbit;

  @override
  void initState() {
    super.initState();
    _currentHabbit = widget.habbit;
  }

  HabbitModel get habbit => _currentHabbit ?? widget.habbit;

  void _saveLog(BuildContext context) async {
    int value = 1;
    bool isCompleted = true;
    if (widget.habbit.type != 'Binary') {
      value = int.tryParse(_inputValue) ?? 1;
      isCompleted = value >= widget.habbit.goalThreshold;
    }

    final sharedPreferences = Provider.of<SharedPreferences>(
      context,
      listen: false,
    );
    final habitsJson = sharedPreferences.getStringList('habbits') ?? [];

    final List<Map<String, dynamic>> habitsList = habitsJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    int habitIndex = habitsList.indexWhere((h) => h['id'] == widget.habbit.id);
    if (habitIndex == -1) return;

    final habitData = habitsList[habitIndex];
    final habitModel = HabbitModel.fromJson(habitData);

    final newLog = HabbitLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      value: value,
      isCompleted: isCompleted,
      note: _noteValue.trim(),
    );

    habitModel.logs.add(newLog);

    // Update progress/streak here if needed
    // For now, let's just save the logs

    habitsList[habitIndex] = habitModel.toJson();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final newHabitsJson = habitsList.map((e) => jsonEncode(e)).toList();
    await sharedPreferences.setStringList('habbits', newHabitsJson);

    if (!mounted) return;
    setState(() {
      _currentHabbit = habitModel;
    });
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Log saved successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
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
          widget.habbit.name,
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(4.0),
            child: Icon(Icons.more_vert_rounded, color: AppColors.grey7),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(10.0),
          child: Divider(color: AppColors.grey3),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 10,
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 16,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Icon(
                            widget.habbit.iconData,
                            color: AppColors.grey1,
                            size: 48,
                          ),
                        ),
                        Column(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.habbit.name,
                              style: GoogleFonts.ubuntu(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey7,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.habbit.description,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey1,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Text(
                                'Current Streak',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey7,
                                ),
                              ),
                              Text(
                                '12 Days',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey1,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Text(
                                'Best Streak',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey7,
                                ),
                              ),
                              Text(
                                '48 Days',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2.0,
                                color: AppColors.primary,
                              ),
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          Text(
                            'Log Today\'s ${widget.habbit.name}',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.grey7,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey7,
                        ),
                      ),
                    ],
                  ),
                  if (widget.habbit.type == 'Binary')
                    GestureDetector(
                      onTap: () => _saveLog(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            Icon(Icons.add, color: AppColors.grey1, size: 30),
                            Text(
                              "Mark Done",
                              style: GoogleFonts.ubuntu(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.grey2,
                              hintText: widget.habbit.type == 'Count'
                                  ? 'Count (e.g. 5)'
                                  : 'Duration (mins)',
                              hintStyle: TextStyle(color: AppColors.grey4),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _inputValue = value;
                              });
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _saveLog(context),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Log",
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.grey2,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.grey2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.grey2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.grey2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      hintText: "Add a quick note.....",
                      hintStyle: TextStyle(color: AppColors.grey4),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _noteValue = value;
                      });
                    },
                  ),
                ],
              ),
              const Text(
                'History',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              HabbitHistoryList(habbit: habbit),
            ],
          ),
        ),
      ),
    );
  }
}
