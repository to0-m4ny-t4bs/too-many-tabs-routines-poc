import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/archives/view_models/archives_viewmodel.dart';
import 'package:too_many_tabs/ui/archives/widgets/routine.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';

class ArchivesScreen extends StatefulWidget {
  const ArchivesScreen({super.key, required this.viewModel});

  final ArchivesViewmodel viewModel;

  @override
  createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<ArchivesScreen> {
  late final AppLifecycleListener _listener;
  final _controller = ScrollController();

  @override
  void initState() {
    _listener = AppLifecycleListener(
      onResume: () async {
        await widget.viewModel.load.execute();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _listener.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkMode
            ? colorScheme.primaryContainer
            : colorScheme.primaryFixed,
        title: Padding(
          padding: EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Text(
                'Backlog',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  color: darkMode
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onPrimaryFixed,
                ),
              ),
            ],
          ),
        ),
        actions: [],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel.load,
              builder: (context, child) {
                final running = widget.viewModel.load.running,
                    error = widget.viewModel.load.error;
                return Loader(
                  error: error,
                  running: running,
                  onError: widget.viewModel.load.execute,
                  child: child!,
                );
              },
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return FadingEdgeScrollView.fromScrollView(
                    gradientFractionOnEnd: 0.8,
                    gradientFractionOnStart: 0,
                    child: CustomScrollView(
                      controller: _controller,
                      slivers: [
                        SliverSafeArea(
                          minimum: EdgeInsets.only(bottom: 120),
                          sliver: SliverList.builder(
                            itemCount: widget.viewModel.routines.length,
                            itemBuilder: (_, index) {
                              return Routine(
                                index: index,
                                key: ValueKey(
                                  widget.viewModel.routines[index].id,
                                ),
                                routine: widget.viewModel.routines[index],
                                restore: () async {
                                  await widget.viewModel.restore.execute(
                                    widget.viewModel.routines[index].id,
                                  );
                                  if (context.mounted) {
                                    context.go(Routes.home);
                                  }
                                },
                                trash: () async {
                                  await widget.viewModel.bin.execute(
                                    widget.viewModel.routines[index].id,
                                  );
                                  await widget.viewModel.load.execute();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingAction(
                onPressed: () {
                  context.go(Routes.bin);
                },
                icon: Icons.archive,
                colorComposition: colorCompositionFromAction(
                  context,
                  ApplicationAction.archiveRoutine,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: FloatingAction(
                onPressed: () => context.go(Routes.home),
                icon: Icons.home,
                colorComposition: colorCompositionFromAction(
                  context,
                  ApplicationAction.toHome,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
