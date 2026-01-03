import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/archives/view_models/archives_viewmodel.dart';
import 'package:too_many_tabs/ui/archives/widgets/archives_screen.dart';
import 'package:too_many_tabs/ui/bin/view_models/bin_viewmodel.dart';
import 'package:too_many_tabs/ui/bin/widgets/bin_screen.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/home_screen.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/notes/widgets/notes_screen.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/widgets/settings_screen.dart';

GoRouter router() => GoRouter(
  restorationScopeId: 'router',
  initialLocation: '${Routes.notes}/94',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final homeViewmodel = HomeViewmodel(
          routinesRepository: context.read(),
          notificationsPlugin: context.read(),
        );
        final notesViewmodel = NotesViewmodel(repo: context.read());
        return HomeScreen(homeModel: homeViewmodel, notesModel: notesViewmodel);
      },
    ),
    GoRoute(
      path: Routes.archives,
      builder: (context, state) {
        final viewModel = ArchivesViewmodel(routinesRepository: context.read());
        return ArchivesScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: Routes.bin,
      builder: (context, state) {
        final viewModel = BinViewmodel(routinesRepository: context.read());
        return BinScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) {
        final viewModel = SettingsViewmodel(repository: context.read());
        return SettingsScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: '${Routes.notes}/:routineId',
      builder: (context, state) {
        debugPrint('${state.pathParameters}');
        final routineId = state.pathParameters['routineId']!;
        final viewModel = NotesViewmodel(
          repo: context.read(),
          routineId: int.parse(routineId),
        );
        return NotesScreen(viewModel: viewModel);
      },
    ),
  ],
);
