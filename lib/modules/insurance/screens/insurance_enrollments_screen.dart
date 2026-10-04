import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/insurance_provider.dart';
import '../widgets/enrollment_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class InsuranceEnrollmentsScreen extends StatefulWidget {
  final bool isStaff;

  const InsuranceEnrollmentsScreen({super.key, this.isStaff = false});

  @override
  State<InsuranceEnrollmentsScreen> createState() =>
      _InsuranceEnrollmentsScreenState();
}

class _InsuranceEnrollmentsScreenState extends State<InsuranceEnrollmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrollments();
      context.read<InsuranceProvider>().loadCompanies();
    });
  }

  void _onTabChanged() {
    // For simple filtering, we'd need to filter client-side or reload with status
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = 'active';
          break;
        case 2:
          _selectedStatus = 'expired';
          break;
      }
    });
    _loadEnrollments();
  }

  void _loadEnrollments() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      context.read<InsuranceProvider>().loadEnrollments(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsuranceProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assurance & Tiers-payant',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gérez vos contrats d\'assurance et prises en charge',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (widget.isStaff) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/insurance/enroll/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau contrat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Actifs'),
                Tab(text: 'Expirés'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(InsuranceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadEnrollments();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    // Filter enrollments by status
    var filtered = provider.enrollments;
    if (_selectedStatus != null) {
      filtered = filtered.where((e) => e.status == _selectedStatus).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun contrat d\'assurance', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de contrat d\'assurance lié à votre compte',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final enrollment = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EnrollmentCard(
            enrollment: enrollment,
            onTap: () => context.push('/insurance/enroll/${enrollment.id}'),
          ),
        );
      },
    );
  }
}
