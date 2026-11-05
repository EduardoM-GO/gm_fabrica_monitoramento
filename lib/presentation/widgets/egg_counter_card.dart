import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/monitoring/monitoring_cubit.dart';
import '../../logic/monitoring/monitoring_state.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/settings/settings_state.dart';

class EggCounterCard extends StatelessWidget {
  const EggCounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<MonitoringCubit, MonitoringState>(
          builder: (context, state) {
            final isAnimating = state.isHitAnimating;

            return Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isAnimating
                      ? AppTheme.eggOrange
                      : AppTheme.surfaceBorder,
                  width: isAnimating ? 2.0 : 1.2,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isAnimating
                      ? [
                          BoxShadow(
                            color: AppTheme.eggOrange.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header row
                    Row(
                      children: [
                        AnimatedScale(
                          scale: isAnimating ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.eggOrange.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.eggOrange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.egg_alt_rounded,
                              color: AppTheme.eggOrange,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CALHA DE OVOS',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.eggOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Sensor Óptico de Passagem',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Sound toggle icon button
                        IconButton(
                          tooltip: settings.eggSoundEnabled
                              ? 'Desativar som do ovo'
                              : 'Ativar som do ovo',
                          icon: Icon(
                            settings.eggSoundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: settings.eggSoundEnabled
                                ? AppTheme.eggOrange
                                : AppTheme.textMuted,
                            size: 22,
                          ),
                          onPressed: () {
                            context
                                .read<SettingsCubit>()
                                .toggleEggSound(!settings.eggSoundEnabled);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Main counter display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedScale(
                          scale: isAnimating ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Text(
                            '${state.rawEggCount}',
                            style: TextStyle(
                              color: isAnimating
                                  ? AppTheme.eggOrange
                                  : AppTheme.textPrimary,
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'unidades totais',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: AppTheme.surfaceElevated, height: 1),
                    const SizedBox(height: 18),

                    // Secondary metrics row: Batch Count & Speed Rate
                    Row(
                      children: [
                        // Batch counter
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.surfaceBorder.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LOTE ATUAL',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${state.batchEggCount}',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    backgroundColor: AppTheme.surfaceElevated,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.restart_alt_rounded,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  label: const Text(
                                    'Zerar',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.read<MonitoringCubit>().resetBatch();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Speed / Flow rate (ovos/min)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.surfaceBorder.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.speed_rounded,
                                      size: 14,
                                      color: AppTheme.eggOrange,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'RITMO DE PRODUÇÃO',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${state.eggsPerMinute.toStringAsFixed(0)} ovos/min',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Test button for immediate hit simulation
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.eggOrange,
                          side: BorderSide(
                            color: AppTheme.eggOrange.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.touch_app_rounded, size: 18),
                        label: const Text(
                          'Testar Passagem (+1 Ovo)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          context.read<MonitoringCubit>().simulateEggHit();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

