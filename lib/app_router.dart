// lib/app_router.dart
import 'package:flutter/material.dart';

// 🌸 Community Dashboard
import 'ui/testing_dashboard.dart';

// 🔐 Auth
import 'auth/login_screen.dart';
import 'auth/role_guard.dart';

// Cameras
import 'camera/esp32_cam_viewer.dart';
import 'camera/cameras_screen.dart';
import 'camera/add_camera_screen.dart';
import 'camera/camera_config_screen.dart';
import 'camera/camera_management.dart';
import 'camera/camera_hub_screen.dart';
import 'camera/find_ip_scan_screen.dart';

// Alerts
import 'alerts/alert_composer.dart';
import 'alerts/alert_view_screen.dart';
import 'alerts/alerts_hub_screen.dart';

// Emergency
import 'emergency/quick_alert_screen.dart';
import 'emergency/panic_screen.dart';
import 'emergency/emergency_alarm_screen.dart';

// Patrol / Escort / Police
import 'escort/escort_screen.dart';
import 'escort/escort_dashboard_screen.dart';
import 'escort/escort_request_screen.dart';

import 'patrol/patrol_request_screen.dart';
import 'patrol/patrol_dashboard_screen.dart';
import 'police/police_dashboard_screen.dart';
import 'breakdown/breakdown_request_screen.dart';
import 'breakdown/breakdown_inbox_screen.dart';
import 'patrol/central_alarm_inbox_screen.dart';

// Community
import 'screens/community/community_report_screen.dart';
import 'screens/community/community_reports_inbox_screen.dart';

// Other features
import 'screens/nearby_services_screen.dart';
import 'settings/settings_screen.dart';
import 'group/groups_screen.dart';
import 'payments/airtime_purchase_screen.dart';
import 'patrol/availability_screen.dart';
import 'admin/patrol_shift_planner_screen.dart';

// Admin
import 'stats/stats_screen.dart';
import 'screens/admin/stats_reset_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/directory_admin_screen.dart';
import 'screens/admin/seed_directory_screen.dart';

// Broadcast
import 'broadcast/broadcast_feed_screen.dart';
import 'broadcast/broadcast_composer_screen.dart';

// Debug
import 'debug/firestore_debug_screen.dart';
import 'admin/role_management_screen.dart';
import 'command/command_center_screen.dart';

Route<dynamic> appOnGenerateRoute(RouteSettings settings) {
  final String name = settings.name ?? '/login';

  switch (name) {
    // =========================================
    // 🔐 LOGIN
    // =========================================
    case '/login':
      return _page(const LoginScreen());

    // =========================================
    // 🌸 COMMUNITY DASHBOARD
    // =========================================
    case '/':
      return _page(
        const RoleGuard(
          requiredRole: 'community',
          child: TestingDashboard(),
        ),
      );

    // =========================================
    // 🔍 NEARBY (FIXED)
    // =========================================
    case '/nearby':
      return _page(const NearbyServicesScreen());

    // =========================================
    // 🎥 CAMERA SYSTEM
    // =========================================
    case '/camera':
    case '/camera/hub':
      return _page(const CameraHubScreen());

    case '/cameras':
      return _page(const CamerasScreen());

    case '/cameras/add':
      return _page(const AddCameraScreen());

    case '/camera/config':
      return _page(const CameraConfigScreen());

    case '/camera/management':
    case '/camera/capture':
      return _page(const CameraManagementScreen());

    case '/camera/find_ip':
      return _page(const FindIpScanScreen());

    case '/esp32cam':
      return _page(
        const Esp32CamViewer(
          url: 'http://192.168.18.25/',
          cameraId: 'cam_block_f_street_1',
        ),
      );

    // =========================================
    // 🔔 ALERTS
    // =========================================
    case '/alerts':
      return _page(const AlertsHubScreen());

    case '/alerts/compose':
      return _page(const AlertComposer());

    case '/alerts/view':
      return _page(const AlertViewScreen());

    // =========================================
    // 🚨 EMERGENCY
    // =========================================
    case '/quick_alert':
      return _page(const QuickAlertScreen());

    case '/panic':
      return _page(const PanicScreen());

    case '/emergency/alarm':
      return _page(
        const EmergencyAlarmScreen(
          areaId: 'Default',
          source: 'phone',
        ),
      );

    // =========================================
    // 👮 POLICE DASHBOARD
    // =========================================
    case '/police':
      return _page(
        const RoleGuard(
          requiredRole: 'police',
          child: PoliceDashboardScreen(),
        ),
      );

    // =========================================
    // 🚓 PATROL DASHBOARD
    // =========================================
    case '/patrol/dashboard':
      return _page(
        const RoleGuard(
          requiredRole: 'patrol',
          child: PatrolDashboard(area: 'Default'),
        ),
      );

    case '/patrol/availability':
      return _page(
        const RoleGuard(
          requiredRole: 'patrol',
          child: AvailabilityScreen(),
        ),
      );

    case '/admin/patrol/planner':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: PatrolShiftPlannerScreen(),
        ),
      );

    case '/central/alarms':
      return _page(
        const RoleGuard(
          requiredRole: 'patrol',
          child: CentralAlarmInboxScreen(areaId: 'Default'),
        ),
      );

    // =========================================
    // 🚗 ESCORT (UNIFIED)
    // =========================================
    case '/escort':
      return _page(const EscortScreen());

    case '/escort/request':
      return _page(const EscortRequestScreen());

    // Patrol request screen now also creates ESCORT requests (see file #2)
    case '/patrol/request':
      return _page(const PatrolRequestScreen());

    // Patrol dispatch (open escort requests)
    case '/escort/dispatch':
    case '/escort/dashboard':
      return _page(
        const RoleGuard(
          requiredRole: 'escort',
          child: EscortDashboardScreen(),
        ),
      );

    // =========================================
    // 🚗 BREAKDOWN
    // =========================================
    case '/breakdown/request':
      return _page(const BreakdownRequestScreen());

    case '/breakdown/inbox':
      return _page(
        const RoleGuard(
          requiredRole: 'towing',
          child: BreakdownInboxScreen(),
        ),
      );

    // =========================================
    // 📣 BROADCAST
    // =========================================
    case '/broadcasts':
      return _page(const BroadcastFeedScreen());

    case '/broadcasts/compose':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: BroadcastComposerScreen(),
        ),
      );

    // =========================================
    // 📊 ADMIN STATS
    // =========================================
    case '/stats':
      return _page(
        const RoleGuard(
          requiredRole: 'patrol',
          child: StatsScreen(),
        ),
      );

    case '/admin/stats_reset':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: StatsResetScreen(),
        ),
      );

    case '/admin/directory':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: DirectoryAdminScreen(),
        ),
      );

    case '/admin/seed':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: SeedDirectoryScreen(),
        ),
      );

    case '/admin/roles':
      return _page(
        const RoleGuard(
          requiredRole: 'admin',
          child: AdminScreen(),
        ),
      );

    // =========================================
    // 💳 PAYMENTS
    // =========================================
    case '/airtime':
      return _page(const AirtimePurchaseScreen());

    // =========================================
    // 📍 COMMUNITY REPORTS
    // =========================================
    case '/community/report':
      final areaId = settings.arguments as String? ?? 'Default';
      return _page(CommunityReportScreen(areaId: areaId));

    case '/community/reports/inbox':
      final areaId = settings.arguments as String? ?? 'Default';
      return _page(CommunityReportsInboxScreen(areaId: areaId));

    // =========================================
    // ⚙ SETTINGS
    // =========================================
    case '/settings':
      return _page(const SettingsScreen());

    case '/group':
      return _page(const GroupsScreen());
    case '/command':
  return _page(const CommandCenterScreen());  

    // =========================================
    // 🔍 DEBUG
    // =========================================
    case '/debug/firestore':
      return _page(const FirestoreDebugScreen());
    case '/admin/roles/manage':
  return _page(
    const RoleGuard(
      requiredRole: 'admin',
      child: RoleManagementScreen(),
    ),
  );  

    // =========================================
    // ❌ FALLBACK
    // =========================================
    default:
      return _page(
        Scaffold(
          appBar: AppBar(title: const Text('Route Not Found')),
          body: Center(
            child: Text('No route defined for "$name"'),
          ),
        
        ),
      );
  }
}

MaterialPageRoute _page(Widget w) => MaterialPageRoute(builder: (_) => w);