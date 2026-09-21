# PharmaConnect — Structure complète du projet

Généré le 28/08/2026. Ce document est un export de l'arborescence réelle du dépôt à cette date
(commande `find`, lecture seule — aucun fichier de code n'a été modifié pour produire ce document).
Pour l'état fonctionnel du code (ce qui est réellement câblé vs mocké), voir `PharmaConnect_CLAUDE.md`.
Pour le contexte portefeuille GSG, voir `CLAUDE.md`. `git log` / `git ls-files` restent la source de
vérité la plus fiable au-delà de cet instantané.

## Vue d'ensemble chiffrée

| Métrique | Valeur |
|---|---|
| Modules sous `lib/modules/` | 34 |
| — dont avec du code Dart | 32 |
| — dont vides (dossier créé, pas encore implémentés) | 2 (`business`, `forecasting`) |
| Fichiers `.dart` sous `lib/` | 475 |
| Migrations SQL sous `supabase/migrations/` | 54 |
| Fichiers de test `.dart` sous `test/` | 47 |

### Top 10 des modules par nombre de fichiers `.dart`

| Module | Fichiers |
|---|---|
| `healthrecord` | 28 |
| `family` | 25 |
| `search` | 22 |
| `loyalty` | 20 |
| `payments` | 18 |
| `stock` | 17 |
| `reservations` | 17 |
| `teleconsult` | 16 |
| `prescriptions` | 16 |
| `traceability` | 15 |

## Arborescence

Racine du dépôt (`pharma_connect/`). Les dossiers de plateforme générés par `flutter create`
(`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) ainsi que les caches de build
(`.dart_tool/`, `build/`, `.idea/`, `.git/`, `node_modules/`, `android/.gradle/`, `supabase/.temp/`)
sont omis ci-dessous — ce sont des artefacts standard, non spécifiques à PharmaConnect.

```
pharma_connect/
├── .github/
│   └── workflows/
│       └── kernel-compliance.yml
├── assets/
│   ├── config/
│   │   └── kernel_config.json
│   ├── fonts/
│   │   ├── Inter/
│   │   │   ├── Inter-Bold.ttf
│   │   │   ├── Inter-Medium.ttf
│   │   │   ├── Inter-Regular.ttf
│   │   │   └── Inter-SemiBold.ttf
│   │   └── JetBrainsMono/
│   │       └── JetBrainsMono-Light.ttf
│   ├── icons/
│   │   └── .gitkeep
│   └── images/
│       └── .gitkeep
├── lib/
│   ├── core/
│   │   ├── kernel/
│   │   │   ├── gsg_kernel_auth_bridge.dart
│   │   │   ├── kernel_badge.dart
│   │   │   ├── kernel_connection_indicator.dart
│   │   │   └── kernel_status.dart
│   │   ├── services/
│   │   │   ├── notification_service.dart
│   │   │   ├── offline_sync_service.dart
│   │   │   ├── push_notification_service.dart
│   │   │   ├── supabase_service.dart
│   │   │   └── whatsapp_service.dart
│   │   ├── theme/
│   │   │   ├── animations.dart
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   ├── glass.dart
│   │   │   ├── spacing.dart
│   │   │   └── typography.dart
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart
│   │   │   ├── export_service.dart
│   │   │   ├── extensions.dart
│   │   │   └── validators.dart
│   │   └── widgets/
│   │       ├── badges/
│   │       │   └── status_badge.dart
│   │       ├── buttons/
│   │       │   ├── danger_button.dart
│   │       │   ├── kernel_button.dart
│   │       │   ├── primary_button.dart
│   │       │   ├── secondary_button.dart
│   │       │   └── tertiary_button.dart
│   │       ├── cards/
│   │       │   ├── glass_card.dart
│   │       │   └── status_card.dart
│   │       ├── inputs/
│   │       │   └── glass_input.dart
│   │       ├── modals/
│   │       │   └── glass_modal.dart
│   │       ├── navigation/
│   │       │   └── sidebar_navigation.dart
│   │       ├── screens/
│   │       │   └── placeholder_screen.dart
│   │       └── confirm_dialog.dart
│   ├── modules/
│   │   ├── admin/
│   │   │   ├── models/
│   │   │   │   ├── admin_permission.dart
│   │   │   │   ├── admin_pharmacy.dart
│   │   │   │   ├── admin_role.dart
│   │   │   │   ├── admin_user.dart
│   │   │   │   ├── audit_log.dart
│   │   │   │   ├── pharmacy_status.dart
│   │   │   │   └── system_config.dart
│   │   │   ├── providers/
│   │   │   │   └── admin_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── admin_dashboard_screen.dart
│   │   │   │   ├── audit_log_screen.dart
│   │   │   │   ├── pharmacies_management_screen.dart
│   │   │   │   ├── system_config_screen.dart
│   │   │   │   └── users_management_screen.dart
│   │   │   ├── services/
│   │   │   │   └── admin_service.dart
│   │   │   └── widgets/
│   │   │       └── admin_pagination.dart
│   │   ├── alerts/
│   │   │   ├── models/
│   │   │   │   ├── alert.dart
│   │   │   │   ├── alert_preferences.dart
│   │   │   │   ├── alert_severity.dart
│   │   │   │   ├── alert_status.dart
│   │   │   │   └── alert_type.dart
│   │   │   ├── providers/
│   │   │   │   └── alert_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── alert_center_screen.dart
│   │   │   │   └── alert_preferences_screen.dart
│   │   │   ├── services/
│   │   │   │   └── alert_service.dart
│   │   │   └── widgets/
│   │   │       ├── alert_card.dart
│   │   │       └── alert_filter_chips.dart
│   │   ├── analytics/
│   │   │   ├── models/
│   │   │   │   ├── analytics_dashboard.dart
│   │   │   │   ├── daily_stats.dart
│   │   │   │   ├── dashboard_widget.dart
│   │   │   │   ├── forecast.dart
│   │   │   │   └── user_dashboard.dart
│   │   │   ├── providers/
│   │   │   │   ├── analytics_provider.dart
│   │   │   │   ├── dashboard_customization_provider.dart
│   │   │   │   └── forecast_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── analytics_dashboard_screen.dart
│   │   │   │   ├── dashboard_editor_screen.dart
│   │   │   │   └── forecast_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── analytics_service.dart
│   │   │   │   ├── dashboard_customization_service.dart
│   │   │   │   └── forecast_ai_service.dart
│   │   │   └── widgets/
│   │   │       └── dashboard_widget_picker.dart
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   ├── phone_country.dart
│   │   │   │   └── user_role.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── license_verification_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── otp_verification_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── two_factor_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── auth_service.dart
│   │   │   │   └── profile_service.dart
│   │   │   └── widgets/
│   │   │       └── phone_input_field.dart
│   │   ├── catalog/
│   │   │   ├── models/
│   │   │   │   ├── category.dart
│   │   │   │   └── manufacturer.dart
│   │   │   ├── providers/
│   │   │   │   └── catalog_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── catalog_detail_screen.dart
│   │   │   │   └── catalog_list_screen.dart
│   │   │   ├── services/
│   │   │   │   └── catalog_service.dart
│   │   │   └── widgets/
│   │   │       ├── category_filter.dart
│   │   │       ├── pagination_controls.dart
│   │   │       ├── product_grid_item.dart
│   │   │       └── product_image.dart
│   │   ├── chains/
│   │   │   ├── models/
│   │   │   │   ├── group_member.dart
│   │   │   │   ├── pharmacy_group.dart
│   │   │   │   └── stock_transfer.dart
│   │   │   ├── providers/
│   │   │   │   └── chain_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── group_create_screen.dart
│   │   │   │   ├── group_detail_screen.dart
│   │   │   │   ├── group_edit_screen.dart
│   │   │   │   ├── groups_list_screen.dart
│   │   │   │   ├── transfer_create_screen.dart
│   │   │   │   └── transfer_detail_screen.dart
│   │   │   ├── services/
│   │   │   │   └── chain_service.dart
│   │   │   └── widgets/
│   │   │       ├── group_card.dart
│   │   │       ├── group_member_tile.dart
│   │   │       └── transfer_card.dart
│   │   ├── coldchain/
│   │   │   ├── models/
│   │   │   │   ├── cold_equipment.dart
│   │   │   │   ├── cold_incident.dart
│   │   │   │   ├── equipment_status.dart
│   │   │   │   ├── equipment_type.dart
│   │   │   │   ├── record_type.dart
│   │   │   │   └── temperature_record.dart
│   │   │   ├── providers/
│   │   │   │   └── coldchain_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── coldchain_dashboard_screen.dart
│   │   │   │   ├── equipment_add_screen.dart
│   │   │   │   └── equipment_detail_screen.dart
│   │   │   ├── services/
│   │   │   │   └── coldchain_service.dart
│   │   │   └── widgets/
│   │   │       ├── equipment_card.dart
│   │   │       ├── incident_tile.dart
│   │   │       └── temperature_record_tile.dart
│   │   ├── dashboard/
│   │   │   ├── models/
│   │   │   │   └── dashboard_data.dart
│   │   │   ├── providers/
│   │   │   │   └── dashboard_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── activity_timeline.dart
│   │   │   │   ├── alert_center.dart
│   │   │   │   ├── quick_action_grid.dart
│   │   │   │   └── role_based_dashboard.dart
│   │   │   └── dashboard_screen.dart
│   │   ├── delivery/
│   │   │   ├── models/
│   │   │   │   ├── delivery.dart
│   │   │   │   ├── delivery_driver.dart
│   │   │   │   ├── delivery_proof.dart
│   │   │   │   ├── delivery_route.dart
│   │   │   │   └── delivery_status.dart
│   │   │   ├── providers/
│   │   │   │   └── delivery_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── delivery_history_screen.dart
│   │   │   │   ├── delivery_schedule_screen.dart
│   │   │   │   ├── delivery_tracking_screen.dart
│   │   │   │   └── driver_dashboard_screen.dart
│   │   │   ├── services/
│   │   │   │   └── delivery_service.dart
│   │   │   └── widgets/
│   │   │       ├── delivery_card.dart
│   │   │       ├── delivery_status_badge.dart
│   │   │       ├── delivery_timeline.dart
│   │   │       └── driver_info_card.dart
│   │   ├── eprescription/
│   │   │   ├── models/
│   │   │   │   ├── eprescription.dart
│   │   │   │   ├── eprescription_history.dart
│   │   │   │   └── eprescription_item.dart
│   │   │   ├── providers/
│   │   │   │   └── eprescription_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── eprescription_detail_screen.dart
│   │   │   │   ├── eprescription_list_screen.dart
│   │   │   │   └── scanner_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── eprescription_service.dart
│   │   │   │   └── scanner_service.dart
│   │   │   └── widgets/
│   │   │       └── eprescription_card.dart
│   │   ├── family/
│   │   │   ├── models/
│   │   │   │   ├── family_activity.dart
│   │   │   │   ├── family_alert.dart
│   │   │   │   ├── family_alert_type.dart
│   │   │   │   ├── family_challenge.dart
│   │   │   │   ├── family_challenge_contribution.dart
│   │   │   │   ├── family_link.dart
│   │   │   │   ├── family_link_status.dart
│   │   │   │   └── sos_alert.dart
│   │   │   ├── providers/
│   │   │   │   ├── family_challenge_provider.dart
│   │   │   │   └── family_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── family_challenge_detail_screen.dart
│   │   │   │   ├── family_challenges_screen.dart
│   │   │   │   ├── family_detail_screen.dart
│   │   │   │   ├── family_journal_screen.dart
│   │   │   │   ├── family_list_screen.dart
│   │   │   │   ├── family_new_screen.dart
│   │   │   │   └── sos_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── family_challenge_service.dart
│   │   │   │   ├── family_service.dart
│   │   │   │   ├── sos_service.dart
│   │   │   │   └── translation_service.dart
│   │   │   └── widgets/
│   │   │       ├── family_activity_tile.dart
│   │   │       ├── family_alert_badge.dart
│   │   │       ├── family_challenge_card.dart
│   │   │       └── family_link_card.dart
│   │   ├── financing/
│   │   │   ├── models/
│   │   │   │   ├── credit_score.dart
│   │   │   │   ├── financing_repayment.dart
│   │   │   │   └── financing_request.dart
│   │   │   ├── providers/
│   │   │   │   └── financing_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── financing_dashboard_screen.dart
│   │   │   │   ├── request_create_screen.dart
│   │   │   │   └── request_detail_screen.dart
│   │   │   ├── services/
│   │   │   │   └── financing_service.dart
│   │   │   └── widgets/
│   │   │       └── financing_card.dart
│   │   ├── healthrecord/
│   │   │   ├── models/
│   │   │   │   ├── health_goal.dart
│   │   │   │   ├── health_milestone.dart
│   │   │   │   ├── health_record.dart
│   │   │   │   ├── health_record_summary.dart
│   │   │   │   ├── preventive_alert.dart
│   │   │   │   └── preventive_alert_history.dart
│   │   │   ├── providers/
│   │   │   │   ├── health_goal_provider.dart
│   │   │   │   ├── health_record_ai_provider.dart
│   │   │   │   ├── health_record_provider.dart
│   │   │   │   └── preventive_alert_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── health_goal_create_screen.dart
│   │   │   │   ├── health_goals_screen.dart
│   │   │   │   ├── health_milestones_screen.dart
│   │   │   │   ├── health_record_detail_screen.dart
│   │   │   │   ├── health_record_edit_screen.dart
│   │   │   │   ├── health_record_list_screen.dart
│   │   │   │   ├── preventive_alert_create_screen.dart
│   │   │   │   └── preventive_alerts_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── health_goal_service.dart
│   │   │   │   ├── health_record_ai_service.dart
│   │   │   │   ├── health_record_service.dart
│   │   │   │   └── preventive_alert_service.dart
│   │   │   └── widgets/
│   │   │       ├── allergy_tile.dart
│   │   │       ├── condition_tile.dart
│   │   │       ├── health_goal_card.dart
│   │   │       ├── health_record_card.dart
│   │   │       ├── medication_tile.dart
│   │   │       └── vaccination_tile.dart
│   │   ├── homecare/
│   │   │   ├── models/
│   │   │   │   ├── homecare_availability_slot.dart
│   │   │   │   ├── homecare_status.dart
│   │   │   │   └── intervention.dart
│   │   │   ├── providers/
│   │   │   │   ├── homecare_provider.dart
│   │   │   │   └── offline_homecare_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── homecare_booking_screen.dart
│   │   │   │   ├── homecare_detail_screen.dart
│   │   │   │   ├── homecare_list_screen.dart
│   │   │   │   └── offline_homecare_screen.dart
│   │   │   ├── services/
│   │   │   │   └── homecare_service.dart
│   │   │   └── widgets/
│   │   │       └── intervention_card.dart
│   │   ├── hospitals/
│   │   │   ├── models/
│   │   │   │   ├── hospital.dart
│   │   │   │   ├── hospital_type.dart
│   │   │   │   └── hospital_wait_time.dart
│   │   │   ├── providers/
│   │   │   │   └── hospitals_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── hospital_detail_screen.dart
│   │   │   │   ├── hospital_wait_times_screen.dart
│   │   │   │   └── hospitals_list_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── hospitals_service.dart
│   │   │   │   └── wait_time_service.dart
│   │   │   └── widgets/
│   │   │       └── hospital_card.dart
│   │   ├── insurance/
│   │   │   ├── models/
│   │   │   │   ├── insurance_company.dart
│   │   │   │   ├── insurance_enrollment.dart
│   │   │   │   └── reimbursement_tracking.dart
│   │   │   ├── providers/
│   │   │   │   └── insurance_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── enrollment_detail_screen.dart
│   │   │   │   ├── insurance_enrollments_screen.dart
│   │   │   │   └── reimbursement_status_screen.dart
│   │   │   ├── services/
│   │   │   │   └── insurance_service.dart
│   │   │   └── widgets/
│   │   │       └── enrollment_card.dart
│   │   ├── iot/
│   │   │   ├── models/
│   │   │   │   ├── iot_alert.dart
│   │   │   │   ├── iot_device.dart
│   │   │   │   └── temperature_reading.dart
│   │   │   ├── providers/
│   │   │   │   └── iot_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── device_create_screen.dart
│   │   │   │   ├── device_detail_screen.dart
│   │   │   │   └── iot_dashboard_screen.dart
│   │   │   ├── services/
│   │   │   │   └── iot_service.dart
│   │   │   └── widgets/
│   │   │       └── device_card.dart
│   │   ├── loyalty/
│   │   │   ├── models/
│   │   │   │   ├── health_challenge.dart
│   │   │   │   ├── loyalty_account.dart
│   │   │   │   ├── loyalty_badge.dart
│   │   │   │   ├── loyalty_reward.dart
│   │   │   │   ├── loyalty_transaction.dart
│   │   │   │   ├── patient_badge.dart
│   │   │   │   └── personalized_reward.dart
│   │   │   ├── providers/
│   │   │   │   ├── badge_provider.dart
│   │   │   │   ├── loyalty_ai_provider.dart
│   │   │   │   ├── loyalty_provider.dart
│   │   │   │   └── personalized_reward_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── badges_gallery_screen.dart
│   │   │   │   ├── challenges_dashboard_screen.dart
│   │   │   │   ├── leaderboard_screen.dart
│   │   │   │   ├── loyalty_dashboard_screen.dart
│   │   │   │   └── personalized_rewards_screen.dart
│   │   │   └── services/
│   │   │       ├── badge_service.dart
│   │   │       ├── loyalty_ai_service.dart
│   │   │       ├── loyalty_service.dart
│   │   │       └── personalized_reward_service.dart
│   │   ├── marketplace/
│   │   │   ├── models/
│   │   │   │   ├── b2b_negotiation.dart
│   │   │   │   ├── b2b_offer.dart
│   │   │   │   └── b2b_order.dart
│   │   │   ├── providers/
│   │   │   │   └── marketplace_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── marketplace_home_screen.dart
│   │   │   │   ├── offer_create_screen.dart
│   │   │   │   ├── offer_detail_screen.dart
│   │   │   │   └── order_detail_screen.dart
│   │   │   └── services/
│   │   │       └── marketplace_service.dart
│   │   ├── payments/
│   │   │   ├── models/
│   │   │   │   ├── installment.dart
│   │   │   │   ├── invoice.dart
│   │   │   │   ├── payment_method.dart
│   │   │   │   ├── transaction.dart
│   │   │   │   ├── transaction_status.dart
│   │   │   │   └── wallet.dart
│   │   │   ├── providers/
│   │   │   │   └── payment_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── dispute_screen.dart
│   │   │   │   ├── installment_plan_screen.dart
│   │   │   │   ├── payment_screen.dart
│   │   │   │   ├── reconciliation_screen.dart
│   │   │   │   ├── transaction_detail_screen.dart
│   │   │   │   ├── transaction_history_screen.dart
│   │   │   │   └── wallet_screen.dart
│   │   │   ├── services/
│   │   │   │   └── payment_service.dart
│   │   │   └── widgets/
│   │   │       ├── payment_method_selector.dart
│   │   │       ├── transaction_list_tile.dart
│   │   │       └── wallet_balance_card.dart
│   │   ├── prescriptions/
│   │   │   ├── models/
│   │   │   │   ├── e_prescription.dart
│   │   │   │   ├── prescription.dart
│   │   │   │   ├── prescription_item.dart
│   │   │   │   └── prescription_status.dart
│   │   │   ├── providers/
│   │   │   │   └── prescription_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── patient_history_screen.dart
│   │   │   │   ├── prescription_detail_screen.dart
│   │   │   │   ├── prescription_list_screen.dart
│   │   │   │   ├── prescription_preview_screen.dart
│   │   │   │   └── prescription_upload_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── ocr_service.dart
│   │   │   │   └── prescription_service.dart
│   │   │   └── widgets/
│   │   │       ├── ocr_confidence_indicator.dart
│   │   │       ├── prescription_card.dart
│   │   │       ├── prescription_item_tile.dart
│   │   │       └── upload_guidance_overlay.dart
│   │   ├── professionals/
│   │   │   ├── models/
│   │   │   │   ├── professional_availability.dart
│   │   │   │   ├── professional_profile.dart
│   │   │   │   ├── professional_qualification.dart
│   │   │   │   ├── professional_review.dart
│   │   │   │   └── professional_specialty.dart
│   │   │   ├── providers/
│   │   │   │   └── professionals_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── professional_detail_screen.dart
│   │   │   │   ├── professional_reviews_screen.dart
│   │   │   │   └── professionals_list_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── professionals_service.dart
│   │   │   │   └── review_service.dart
│   │   │   └── widgets/
│   │   │       └── professional_card.dart
│   │   ├── recall/
│   │   │   ├── models/
│   │   │   │   ├── batch_recall_status.dart
│   │   │   │   ├── recall.dart
│   │   │   │   ├── recall_affected_batch.dart
│   │   │   │   ├── recall_severity.dart
│   │   │   │   └── recall_status.dart
│   │   │   ├── providers/
│   │   │   │   └── recall_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── recall_create_screen.dart
│   │   │   │   ├── recall_dashboard_screen.dart
│   │   │   │   └── recall_detail_screen.dart
│   │   │   ├── services/
│   │   │   │   └── recall_service.dart
│   │   │   └── widgets/
│   │   │       ├── affected_batch_tile.dart
│   │   │       ├── recall_card.dart
│   │   │       ├── recall_filter_chips.dart
│   │   │       └── recall_status_chip.dart
│   │   ├── regulator/
│   │   │   ├── models/
│   │   │   │   └── adverse_reaction.dart
│   │   │   ├── providers/
│   │   │   │   └── regulator_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── adverse_reaction_detail_screen.dart
│   │   │   │   ├── adverse_reaction_report_screen.dart
│   │   │   │   └── adverse_reactions_list_screen.dart
│   │   │   ├── services/
│   │   │   │   └── regulator_service.dart
│   │   │   └── widgets/
│   │   │       └── adverse_reaction_card.dart
│   │   ├── reservations/
│   │   │   ├── models/
│   │   │   │   ├── reservation.dart
│   │   │   │   ├── reservation_item.dart
│   │   │   │   ├── reservation_status.dart
│   │   │   │   └── timeslot.dart
│   │   │   ├── providers/
│   │   │   │   └── reservation_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── cart_screen.dart
│   │   │   │   ├── pharmacy_queue_screen.dart
│   │   │   │   ├── reservation_checkout_screen.dart
│   │   │   │   ├── reservation_confirmation_screen.dart
│   │   │   │   ├── reservation_history_screen.dart
│   │   │   │   └── reservation_qr_screen.dart
│   │   │   ├── services/
│   │   │   │   └── reservation_service.dart
│   │   │   └── widgets/
│   │   │       ├── cart_item_tile.dart
│   │   │       ├── checkout_step_indicator.dart
│   │   │       ├── queue_position_widget.dart
│   │   │       ├── reservation_status_card.dart
│   │   │       └── timeslot_picker.dart
│   │   ├── search/
│   │   │   ├── models/
│   │   │   │   ├── availability_result.dart
│   │   │   │   ├── pharmacy.dart
│   │   │   │   ├── search_filters.dart
│   │   │   │   ├── search_result.dart
│   │   │   │   └── search_suggestion.dart
│   │   │   ├── providers/
│   │   │   │   └── search_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── barcode_scanner_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── search_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── location_service.dart
│   │   │   │   └── search_service.dart
│   │   │   └── widgets/
│   │   │       ├── availability_badge.dart
│   │   │       ├── filter_chips.dart
│   │   │       ├── pharmacy_list_tile.dart
│   │   │       ├── product_card.dart
│   │   │       ├── search_bar.dart
│   │   │       ├── search_bar_with_suggestions.dart
│   │   │       ├── search_empty_state.dart
│   │   │       ├── search_error_state.dart
│   │   │       ├── search_filter_bottom_sheet.dart
│   │   │       ├── search_result_card.dart
│   │   │       └── search_skeleton.dart
│   │   ├── solidarity/
│   │   │   ├── models/
│   │   │   │   ├── solidarity_beneficiary.dart
│   │   │   │   └── solidarity_program.dart
│   │   │   ├── providers/
│   │   │   │   └── solidarity_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── solidarity_dashboard_screen.dart
│   │   │   ├── services/
│   │   │   │   └── solidarity_service.dart
│   │   │   └── widgets/
│   │   │       └── program_card.dart
│   │   ├── stock/
│   │   │   ├── models/
│   │   │   │   ├── pharmacy_group.dart
│   │   │   │   ├── stock_adjustment.dart
│   │   │   │   ├── stock_batch.dart
│   │   │   │   ├── stock_item.dart
│   │   │   │   ├── stock_movement.dart
│   │   │   │   └── stock_status.dart
│   │   │   ├── providers/
│   │   │   │   └── stock_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── stock_adjustment_screen.dart
│   │   │   │   ├── stock_alerts_screen.dart
│   │   │   │   ├── stock_detail_screen.dart
│   │   │   │   ├── stock_list_screen.dart
│   │   │   │   └── stock_movements_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── forecast_service.dart
│   │   │   │   ├── stock_service.dart
│   │   │   │   └── stock_summary_card.dart
│   │   │   └── widgets/
│   │   │       ├── stock_batch_tile.dart
│   │   │       └── stock_status_chip.dart
│   │   ├── support/
│   │   │   ├── models/
│   │   │   │   ├── bot_conversation.dart
│   │   │   │   ├── ticket.dart
│   │   │   │   └── ticket_response.dart
│   │   │   ├── providers/
│   │   │   │   ├── bot_provider.dart
│   │   │   │   └── support_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── chat_bot_screen.dart
│   │   │   │   ├── new_ticket_screen.dart
│   │   │   │   ├── support_list_screen.dart
│   │   │   │   └── ticket_detail_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── bot_ai_service.dart
│   │   │   │   ├── support_service.dart
│   │   │   │   └── whatsapp_support_service.dart
│   │   │   └── widgets/
│   │   │       ├── ticket_card.dart
│   │   │       └── whatsapp_support_button.dart
│   │   ├── teleconsult/
│   │   │   ├── models/
│   │   │   │   ├── async_message.dart
│   │   │   │   ├── availability_slot.dart
│   │   │   │   ├── consultation.dart
│   │   │   │   ├── consultation_status.dart
│   │   │   │   └── pre_consultation.dart
│   │   │   ├── providers/
│   │   │   │   ├── pre_consultation_provider.dart
│   │   │   │   └── teleconsult_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── async_messaging_screen.dart
│   │   │   │   ├── pre_consultation_screen.dart
│   │   │   │   ├── teleconsult_booking_screen.dart
│   │   │   │   ├── teleconsult_detail_screen.dart
│   │   │   │   └── teleconsult_list_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── messaging_service.dart
│   │   │   │   ├── pre_consultation_ai_service.dart
│   │   │   │   └── teleconsult_service.dart
│   │   │   └── widgets/
│   │   │       └── consultation_card.dart
│   │   ├── traceability/
│   │   │   ├── models/
│   │   │   │   ├── batch_movement.dart
│   │   │   │   ├── batch_status.dart
│   │   │   │   ├── certificate.dart
│   │   │   │   ├── cold_chain_record.dart
│   │   │   │   ├── traceable_batch.dart
│   │   │   │   └── verification_result.dart
│   │   │   ├── providers/
│   │   │   │   └── traceability_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── batch_detail_screen.dart
│   │   │   │   ├── traceability_dashboard_screen.dart
│   │   │   │   └── verification_screen.dart
│   │   │   ├── services/
│   │   │   │   └── traceability_service.dart
│   │   │   └── widgets/
│   │   │       ├── batch_status_chip.dart
│   │   │       ├── movement_timeline.dart
│   │   │       ├── scan_fab.dart
│   │   │       └── verification_result_card.dart
│   │   ├── triage/
│   │   │   ├── models/
│   │   │   │   ├── triage_ai_analysis.dart
│   │   │   │   ├── triage_assessment.dart
│   │   │   │   ├── triage_patient.dart
│   │   │   │   └── triage_status.dart
│   │   │   ├── providers/
│   │   │   │   ├── triage_ai_provider.dart
│   │   │   │   └── triage_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── triage_ai_screen.dart
│   │   │   │   ├── triage_detail_screen.dart
│   │   │   │   ├── triage_list_screen.dart
│   │   │   │   └── triage_new_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── triage_ai_service.dart
│   │   │   │   └── triage_service.dart
│   │   │   └── widgets/
│   │   │       └── triage_patient_card.dart
│   │   ├── business/               (vide — pas encore implémenté)
│   │   └── forecasting/            (vide — pas encore implémenté)
│   ├── routes/
│   │   └── app_router.dart
│   ├── shared/
│   │   ├── models/
│   │   │   └── product.dart
│   │   ├── providers/           (vide)
│   │   ├── repositories/        (vide)
│   │   └── services/            (vide)
│   ├── app.dart
│   └── main.dart
├── scripts/
│   └── ci/
│       ├── check_no_cross_schema_fk.sh
│       ├── check_no_hardcoded_color.sh
│       └── check_no_hardcoded_currency.sh
├── supabase/
│   ├── migrations/               (54 fichiers, voir liste ci-dessous)
│   │   ├── 20260827000100_extensions_and_helpers.sql
│   │   ├── 20260827000200_profiles.sql
│   │   ├── 20260827000300_catalog.sql
│   │   ├── 20260827000400_pharmacies.sql
│   │   ├── 20260827000500_admin.sql
│   │   ├── 20260827000600_stock.sql
│   │   ├── 20260827000700_traceability.sql
│   │   ├── 20260827000800_coldchain.sql
│   │   ├── 20260827000900_recall.sql
│   │   ├── 20260827001000_prescriptions.sql
│   │   ├── 20260827001100_reservations.sql
│   │   ├── 20260827001200_delivery.sql
│   │   ├── 20260827001300_payments.sql
│   │   ├── 20260827001400_alerts.sql
│   │   ├── 20260827001500_search.sql
│   │   ├── 20260827002000_staff_write_policies.sql
│   │   ├── 20260827003000_health_records.sql
│   │   ├── 20260827003500_teleconsult.sql
│   │   ├── 20260827004000_homecare.sql
│   │   ├── 20260827004500_triage.sql
│   │   ├── 20260827005000_family.sql
│   │   ├── 20260827005500_professionals.sql
│   │   ├── 20260827006000_hospitals.sql
│   │   ├── 20260827006500_regulator.sql
│   │   ├── 20260827007000_insurance.sql
│   │   ├── 20260827007500_analytics.sql
│   │   ├── 20260827008000_support.sql
│   │   ├── 20260827008500_loyalty.sql
│   │   ├── 20260827009000_solidarity.sql
│   │   ├── 20260827009500_eprescription.sql
│   │   ├── 20260828010000_teleconsult_ai.sql
│   │   ├── 20260828011000_healthrecord_ai.sql
│   │   ├── 20260828012000_triage_ai.sql
│   │   ├── 20260828013000_analytics_ai.sql
│   │   ├── 20260828014000_support_ai.sql
│   │   ├── 20260828015000_loyalty_ai.sql
│   │   ├── 20260828016000_gamification_badges.sql
│   │   ├── 20260828016100_gamification_leaderboard.sql
│   │   ├── 20260828016200_gamification_family.sql
│   │   ├── 20260828016300_gamification_health.sql
│   │   ├── 20260828016400_personalized_rewards.sql
│   │   ├── 20260828016500_dashboard_customization.sql
│   │   ├── 20260828017000_offline_sync.sql
│   │   ├── 20260828018000_notifications.sql
│   │   ├── 20260828019000_scanned_prescriptions.sql
│   │   ├── 20260828020000_professional_reviews.sql
│   │   ├── 20260828021000_hospital_wait_times.sql
│   │   ├── 20260828022000_reimbursement_tracking.sql
│   │   ├── 20260828023000_sos_notifications.sql
│   │   ├── 20260828024000_async_messaging.sql
│   │   ├── 20260829000000_chains.sql
│   │   ├── 20260829001000_marketplace.sql
│   │   ├── 20260829002000_financing.sql
│   │   └── 20260829003000_iot.sql
│   ├── config.toml
│   └── seed.sql
├── test/
│   ├── unit/
│   │   └── providers/            (31 fichiers *_provider_test.dart, un par module principal)
│   ├── widget/
│   │   └── screens/              (15 fichiers *_screen_test.dart)
│   └── widget_test.dart
├── .claude/
├── .github/
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── CLAUDE.md                    (contexte portefeuille GSG)
├── PharmaConnect_CLAUDE.md       (état vivant du code, source de vérité fonctionnelle)
├── README.md
├── REFERENTIEL_ARCHITECTE.md
├── STRUCTURE_PROJET.md           (ce document)
├── analysis_options.yaml
├── code_export_architecte.md    (archive de dump de code, non maintenue depuis le 26/08/2026)
├── devtools_options.yaml
├── package-lock.json
├── package.json
├── pharma_connect.iml
├── pubspec.lock
├── pubspec.yaml
│
│   (omis — plateformes Flutter générées automatiquement, non spécifiques au produit)
├── android/
├── ios/
├── linux/
├── macos/
├── web/
└── windows/
```

## Inventaire des modules `lib/modules/`

| Module | Fichiers `.dart` | Sous-dossiers présents |
|---|---:|---|
| healthrecord | 28 | models, providers, screens, services, widgets |
| family | 25 | models, providers, screens, services, widgets |
| search | 22 | models, providers, screens, services, widgets |
| loyalty | 20 | models, providers, screens, services |
| payments | 18 | models, providers, screens, services, widgets |
| stock | 17 | models, providers, screens, services, widgets |
| reservations | 17 | models, providers, screens, services, widgets |
| teleconsult | 16 | models, providers, screens, services, widgets |
| prescriptions | 16 | models, providers, screens, services, widgets |
| traceability | 15 | models, providers, screens, services, widgets |
| delivery | 15 | models, providers, screens, services, widgets |
| analytics | 15 | models, providers, screens, services, widgets |
| admin | 15 | models, providers, screens, services, widgets |
| support | 14 | models, providers, screens, services, widgets |
| recall | 14 | models, providers, screens, services, widgets |
| coldchain | 14 | models, providers, screens, services, widgets |
| chains | 14 | models, providers, screens, services, widgets |
| triage | 13 | models, providers, screens, services, widgets |
| professionals | 12 | models, providers, screens, services, widgets |
| homecare | 11 | models, providers, screens, services, widgets |
| auth | 11 | models, providers, screens, services, widgets |
| alerts | 11 | models, providers, screens, services, widgets |
| hospitals | 10 | models, providers, screens, services, widgets |
| eprescription | 10 | models, providers, screens, services, widgets |
| catalog | 10 | models, providers, screens, services, widgets |
| marketplace | 9 | models, providers, screens, services |
| iot | 9 | models, providers, screens, services, widgets |
| insurance | 9 | models, providers, screens, services, widgets |
| financing | 9 | models, providers, screens, services, widgets |
| regulator | 7 | models, providers, screens, services, widgets |
| dashboard | 7 | models, providers, widgets (+ dashboard_screen.dart) |
| solidarity | 6 | models, providers, screens, services, widgets |
| forecasting | 0 | — |
| business | 0 | — |

## Notes de méthode

- Génération : `find` (arborescence complète), filtré pour exclure `.git/`, `.dart_tool/`, `build/`,
  `.idea/`, `node_modules/`, `android/.gradle/`, `supabase/.temp/`, et les répertoires de plateforme
  natifs (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) — reproductibles à tout moment
  par `flutter create .` et non porteurs d'information métier.
- Mise en forme de l'arbre : reconstruction manuelle à partir de la sortie `find` triée.
- Comptage des fichiers par module : `find lib/modules/<module> -name "*.dart" | wc -l`.
- Depuis le précédent instantané (28/08/2026, matin) : ajout de 4 modules auparavant vides
  (`chains`, `financing`, `iot`, `marketplace`, désormais 9 à 14 fichiers chacun), extension de
  plusieurs modules existants (healthrecord +6, family +4, loyalty +4, teleconsult/hospitals/
  insurance/professionals/eprescription/homecare/support/analytics), ajout de 14 migrations SQL
  et de 3 fichiers de test provider (`chain`, `financing`, `iot`), et ajout de 3 services transverses
  sous `lib/core/services/` (`offline_sync_service.dart`, `push_notification_service.dart`,
  `whatsapp_service.dart`). `business` et `forecasting` restent les deux seuls modules vides.
- Cet export est un **instantané** — pour l'état courant, préférer `git ls-files` ou explorer le
  dépôt directement, en particulier après plusieurs jours d'écart avec la date de génération ci-dessus.
