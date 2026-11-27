import 'package:flutter/widgets.dart';
import 'package:tashil_real_estate/features/agency_mandates/services/mandate_service.dart';

/// A [StreamBuilder] that opens its stream once per [cacheKey] instead of on every rebuild, so a
/// parent rebuilding does not restart the Firestore listener.
class MandateStream<T> extends StatefulWidget {
  final Object cacheKey;
  final Stream<T> Function() open;
  final AsyncWidgetBuilder<T> builder;

  const MandateStream({super.key, required this.cacheKey, required this.open, required this.builder});

  @override
  State<MandateStream<T>> createState() => _MandateStreamState<T>();
}

class _MandateStreamState<T> extends State<MandateStream<T>> {
  late Stream<T> _stream = MandateService.safe(widget.open);

  @override
  void didUpdateWidget(MandateStream<T> old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey) _stream = MandateService.safe(widget.open);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(stream: _stream, builder: widget.builder);
}
