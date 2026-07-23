import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/pages/add_habbit.dart';
import 'package:habbit/pages/log_habbit.dart';

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

  // ── Greeting / date helpers ────────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _todayLabel {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  int get _bestStreak => _habbits.isEmpty
      ? 0
      : _habbits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

  int get _activeStreaks => _habbits.where((h) => h.streak > 0).length;

  Future<void> _openAddHabbit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHabbit()),
    );
    _loadHabbits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: _isLoading || _habbits.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddHabbit,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'New Habit',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
              ),
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadHabbits,
                color: AppColors.primary,
                child: _habbits.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(),
                          const SizedBox(height: 12),
                          ..._habbits.asMap().entries.map(
                            (e) => _buildHabitCard(e.value, e.key),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  // ── App bar: brand icon + greeting/date ────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBrand,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HabitFlow',
                  style: GoogleFonts.ubuntu(
                    color: AppColors.grey7,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _todayLabel,
                  style: GoogleFonts.ubuntu(
                    color: AppColors.grey5,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: AppColors.grey3, height: 1),
      ),
    );
  }

  // ── Hero card: greeting + streak stats ─────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowBrand,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting 👋',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activeStreaks > 0
                ? 'Keep the momentum going!'
                : 'Start a streak today.',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat(
                icon: Icons.grid_view_rounded,
                value: '${_habbits.length}',
                label: 'Habits',
              ),
              _heroDivider(),
              _heroStat(
                icon: Icons.bolt_rounded,
                value: '$_activeStreaks',
                label: 'Active',
              ),
              _heroDivider(),
              _heroStat(
                icon: Icons.emoji_events_rounded,
                value: '${_bestStreak}d',
                label: 'Best streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Habits',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_habbits.length} total',
            style: GoogleFonts.ubuntu(
              color: AppColors.primaryDeep,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Modern habit card ──────────────────────────────────────────────────────
  Widget _buildHabitCard(HabbitModel habbit, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(habbit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        onDismissed: (direction) => _handleDismiss(habbit, index),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogHabbit(habbit: habbit, userId: '1'),
                ),
              );
              _loadHabbits();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.grey3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      habbit.iconData,
                      color: AppColors.primaryDeep,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habbit.name,
                          style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.grey7,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _tag(habbit.frequency, AppColors.grey2,
                                AppColors.grey6),
                            const SizedBox(width: 6),
                            _tag(
                              habbit.type,
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primaryDeep,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _streakBadge(habbit.streak),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.ubuntu(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _streakBadge(int streak) {
    final active = streak > 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: active ? AppColors.streakGradient : null,
            color: active ? null : AppColors.grey2,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: active ? Colors.white : AppColors.grey4,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${streak}d',
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.streak : AppColors.grey4,
          ),
        ),
      ],
    );
  }

  Future<void> _handleDismiss(HabbitModel habbit, int index) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Remove from the UI immediately, but defer the actual DB deletion until
    // the undo window closes.
    setState(() {
      _habbits.removeAt(index);
    });

    bool undone = false;
    final controller = scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        // SnackBar.persist defaults to `action != null`, so having an Undo
        // action makes it stay forever. Force auto-dismiss after `duration`.
        persist: false,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text('"${habbit.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            undone = true;
            if (mounted) {
              setState(() {
                _habbits.insert(index.clamp(0, _habbits.length), habbit);
              });
            }
          },
        ),
      ),
    );

    final reason = await controller.closed;

    // Undo pressed — nothing was ever deleted from the DB, so just stop.
    if (undone || reason == SnackBarClosedReason.action) return;

    // Window elapsed without undo — now delete the habit and its logs online.
    try {
      await DataProvider.deleteHabitWithLogs(habbit.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _habbits.insert(index.clamp(0, _habbits.length), habbit);
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text('Could not delete "${habbit.name}"'),
          ),
        );
      }
    }
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _openAddHabbit,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Your First Habit',
                    style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
