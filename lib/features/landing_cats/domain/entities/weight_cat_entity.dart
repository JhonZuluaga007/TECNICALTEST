import 'package:equatable/equatable.dart';

class WeightEntity extends Equatable {
  const WeightEntity({required this.imperial, required this.metric});

  final String imperial;
  final String metric;

  @override
  List<Object?> get props => [imperial, metric];
}
