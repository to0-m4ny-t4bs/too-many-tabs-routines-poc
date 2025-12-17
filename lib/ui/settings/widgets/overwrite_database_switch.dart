import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/utils/result.dart';

class OverwriteDatabaseSwitch extends StatefulWidget {
  const OverwriteDatabaseSwitch({
    super.key,
    required this.onSwitch,
    required this.initialState,
  });
  final Future<Result<void>> Function() onSwitch;
  final bool initialState;
  @override
  createState() => _OverwriteDatabaseSwitchState();
}

class _OverwriteDatabaseSwitchState extends State<OverwriteDatabaseSwitch> {
  late bool _state;
  final _log = Logger("_OverwriteDatabaseSwitchState");

  @override
  initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  build(BuildContext context) {
    return Switch(
      value: _state,
      onChanged: (bool value) async {
        final resultSwitch = await widget.onSwitch();
        switch (resultSwitch) {
          case Error<void>():
            _log.warning('onSwitch callback: ${resultSwitch.error}');
            return;
          case Ok<void>():
        }
        setState(() {
          _state = value;
        });
      },
    );
  }
}
