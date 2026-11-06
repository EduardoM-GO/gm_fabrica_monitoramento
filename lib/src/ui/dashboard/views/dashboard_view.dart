import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_breakpoints.dart';
import '../../../core/themes/app_motion.dart';
import '../../../core/themes/app_theme.dart';
import '../../freezer/view_models/freezer_viewmodel.dart';
import '../../freezer/views/freezer_batch_card.dart';
import '../../production/views/egg_packaging_hero_card.dart';

/// Main Dashboard View providing dual-zone monitoring for factory operators.
/// Adheres strictly to Material Design 3, App Architecture guidelines, and responsive breakpoints.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final freezerViewModel = context.watch<FreezerViewModel>();
    final freezers = freezerViewModel.state.activeFreezers;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = AppBreakpoints.isLandscape(context);
            final isWideEnough =
                constraints.maxWidth >= AppBreakpoints.compactMax;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: isLandscape && isWideEnough
                  ? _buildLandscapeDualZone(freezers)
                  : _buildPortraitStack(freezers),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLandscapeDualZone(List<FreezerViewData> freezers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Zone (flex: 6): Packaging operator focus
        const Expanded(flex: 6, child: EggPackagingHeroCard()),

        const SizedBox(width: 10),

        // Right Zone (flex: 4): Freezers / Room 4x4m focus
        Expanded(
          flex: 4,
          child: AnimatedSwitcher(
            duration: AppMotion.durationStandard,
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.easeOut,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: freezers.isEmpty
                ? KeyedSubtree(
                    key: const ValueKey('empty_freezers_landscape'),
                    child: _buildEmptyFreezerPlaceholder(),
                  )
                : KeyedSubtree(
                    key: const ValueKey('freezers_landscape_column'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < freezers.length; i++) ...[
                          FreezerBatchCard(
                            freezer: freezers[i],
                            freezerNumber: i + 1,
                          ),
                          if (i < freezers.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitStack(List<FreezerViewData> freezers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EggPackagingHeroCard(),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppMotion.durationStandard,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: AppMotion.easeOut),
                ),
                child: child,
              ),
            );
          },
          child: freezers.isEmpty
              ? KeyedSubtree(
                  key: const ValueKey('empty_freezers_portrait'),
                  child: _buildEmptyFreezerPlaceholder(),
                )
              : KeyedSubtree(
                  key: const ValueKey('freezers_portrait_column'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < freezers.length; i++) ...[
                        FreezerBatchCard(
                          freezer: freezers[i],
                          freezerNumber: i + 1,
                        ),
                        if (i < freezers.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyFreezerPlaceholder() {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.surfaceElevated),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.kitchen_rounded, size: 32, color: AppTheme.textMuted),
              SizedBox(height: 8),
              Text(
                'Aguardando telemetria dos freezers...',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias matching Flutter conventions
typedef DashboardScreen = DashboardView;
