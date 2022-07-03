import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'bloc.dart';

class BlockProvider<T extends Bloc> extends StatefulWidget {
  final Widget child;
  final T bloc;

  const BlockProvider({Key? key, required this.bloc, required this.child})
      : super(key: key);

  //2
  static T of<T extends Bloc>(BuildContext context) {
    final BlockProvider<T> provider = context.findAncestorWidgetOfExactType()!;
    return provider.bloc;
  }

  @override
  State<BlockProvider> createState() => _BlockProviderState();
}

class _BlockProviderState extends State<BlockProvider> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }
}
