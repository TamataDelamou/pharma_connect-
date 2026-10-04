import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../models/verification_result.dart';
import '../../../core/theme/palette.dart';

class VerificationResultCard extends StatefulWidget {
  final VerificationResult result;

  const VerificationResultCard({super.key, required this.result});

  @override
  State<VerificationResultCard> createState() => _VerificationResultCardState();
}

class _VerificationResultCardState extends State<VerificationResultCard>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleController.forward();
      if (widget.result.isAuthentic && !widget.result.isRecalled) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthentic = widget.result.isAuthentic && !widget.result.isRecalled;
    final isRecalled = widget.result.isRecalled;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + 0.2 * _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAuthentic
                        ? [
                            context.palette.success.withValues(alpha: 0.2),
                            context.palette.success.withValues(alpha: 0.05),
                          ]
                        : isRecalled
                        ? [
                            context.palette.warning.withValues(alpha: 0.2),
                            context.palette.warning.withValues(alpha: 0.05),
                          ]
                        : [
                            context.palette.danger.withValues(alpha: 0.2),
                            context.palette.danger.withValues(alpha: 0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAuthentic
                        ? context.palette.success
                        : isRecalled
                        ? context.palette.warning
                        : context.palette.danger,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isAuthentic
                                  ? context.palette.success
                                  : isRecalled
                                  ? context.palette.warning
                                  : context.palette.danger)
                              .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: isAuthentic
                        ? Lottie.asset(
                            'assets/animations/verified.json',
                            repeat: false,
                          )
                        : isRecalled
                        ? Lottie.asset(
                            'assets/animations/warning.json',
                            repeat: false,
                          )
                        : Lottie.asset(
                            'assets/animations/error.json',
                            repeat: false,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.statusLabel,
                          style: context.text.heading3.copyWith(
                            color: isAuthentic
                                ? context.palette.success
                                : isRecalled
                                ? context.palette.warning
                                : context.palette.danger,
                          ),
                        ),
                        if (widget.result.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.result.message!,
                            style: context.text.body2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.result.productName != null) ...[
                Divider(color: context.palette.veil(0.12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Produit', style: context.text.label),
                          Text(widget.result.productName!),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lot', style: context.text.label),
                          Text(widget.result.batchNumber ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.result.manufacturer != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fabricant', style: context.text.label),
                            Text(widget.result.manufacturer!),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Péremption', style: context.text.label),
                            Text(
                              widget.result.expiryDate != null
                                  ? '${widget.result.expiryDate!.day}/${widget.result.expiryDate!.month}/${widget.result.expiryDate!.year}'
                                  : '',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (isRecalled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.palette.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.palette.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: context.palette.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ Ce produit fait l\'objet d\'un rappel. Consultez les détails.',
                            style: context.text.body2.copyWith(
                              color: context.palette.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Naviguer vers le rappel associé
                          },
                          child: const Text('Voir le rappel'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Text(
                'Vérifié le ${_formatDateTime(widget.result.timestamp)}',
                style: context.text.micro,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Partager le résultat
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Partager'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isAuthentic) ...[
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                context.palette.success,
                context.palette.info,
                context.palette.warningStrong,
                context.palette.danger,
                context.palette.secondary,
              ],
              numberOfParticles: 20,
              gravity: 0.1,
              maxBlastForce: 10,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
