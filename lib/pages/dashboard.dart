import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/habbit_card.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/pages/add_habbit.dart';
import 'package:habbit/pages/log_habbit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<HabbitModel> _habbits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabbits();
    });
  }

  Future<void> _loadHabbits() async {
    setState(() {
      _isLoading = true;
    });

    final loadedHabbits = await DataProvider.getData(DataProvider.habitsRef);

    setState(() {
      _habbits = loadedHabbits;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(4.0),
          padding: const EdgeInsets.all(10.0),
          decoration: const BoxDecoration(color: AppColors.grey7),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.grey1,
          ),
        ),
        title: Text(
          'HabitFlow',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                border: Border.all(width: 4.0, color: AppColors.primary),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 30),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddHabbit()),
              );
              _loadHabbits();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10.0),
          child: Divider(color: AppColors.grey3),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : _habbits.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.spa_rounded,
                        size: 80,
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No habits tracked yet',
                        style: GoogleFonts.ubuntu(
                          color: AppColors.grey7,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a habit to build healthy routines and achieve consistency.',
                        style: GoogleFonts.ubuntu(
                          color: AppColors.grey5,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddHabbit(),
                            ),
                          );
                          _loadHabbits();
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Add Your First Habbit',
                          style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: _habbits.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final habbit = _habbits[index];
                  return Dismissible(
                    key: Key(habbit.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      final sharedPreferences = Provider.of<SharedPreferences>(
                        context,
                        listen: false,
                      );
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      setState(() {
                        _habbits.removeAt(index);
                      });

                      final habitsJson = _habbits
                          .map((e) => jsonEncode(e.toJson()))
                          .toList();
                      await sharedPreferences.setStringList(
                        'habbits',
                        habitsJson,
                      );

                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('"${habbit.name}" deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () async {
                                setState(() {
                                  _habbits.insert(index, habbit);
                                });
                                final undoJson = _habbits
                                    .map((e) => jsonEncode(e.toJson()))
                                    .toList();
                                await sharedPreferences.setStringList(
                                  'habbits',
                                  undoJson,
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LogHabbit(habbit: habbit, userId: '1'),
                          ),
                        );
                        _loadHabbits();
                      },
                      child: HabbitCard(
                        title: habbit.name,
                        icon: habbit.iconData,
                        frequency: habbit.frequency,
                        progress: habbit.progress,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
