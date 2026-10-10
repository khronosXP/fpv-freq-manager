import '../../models/fpv_channel.dart';
import 'allocation_score.dart';

/// Результат оптимізації смуги частот.
class BandAllocationResult {
  final List<FpvChannel> channels;
  final AllocationScore score;
  final bool isSuccess;
  final String? errorMessage;

  const BandAllocationResult({
    required this.channels,
    required this.score,
    required this.isSuccess,
    this.errorMessage,
  });

  const BandAllocationResult.failure(String message)
    : channels = const [],
      score = const AllocationScore(
        imdMargin: 0,
        minSpacing: 0,
        totalSpread: 0,
        totalScore: -1e9,
      ),
      isSuccess = false,
      errorMessage = message;
}
