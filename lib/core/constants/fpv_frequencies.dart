import '../models/fpv_channel.dart';

class FpvFrequencies {
  FpvFrequencies._();

  // Band A (Boscam A)
  static const List<int> bandAFrequencies = [
    5865,
    5845,
    5825,
    5805,
    5785,
    5765,
    5745,
    5725,
  ];

  // Band B (Boscam B)
  static const List<int> bandBFrequencies = [
    5733,
    5752,
    5771,
    5790,
    5809,
    5828,
    5847,
    5866,
  ];

  // Band E (Boscam E)
  static const List<int> bandEFrequencies = [
    5705,
    5685,
    5665,
    5645,
    5885,
    5905,
    5925,
    5945,
  ];

  // Band F (FatShark / Airwave)
  static const List<int> bandFFrequencies = [
    5740,
    5760,
    5780,
    5800,
    5820,
    5840,
    5860,
    5880,
  ];

  // Band R (RaceBand)
  static const List<int> bandRFrequencies = [
    5658,
    5695,
    5732,
    5769,
    5806,
    5843,
    5880,
    5917,
  ];

  // Band L (Lowband / Lowrace)
  static const List<int> bandLFrequencies = [
    5333,
    5373,
    5413,
    5453,
    5493,
    5533,
    5573,
    5613,
  ];

  // Band X (4.9 GHz X-Band)
  static const List<int> bandXFrequencies = [
    4990,
    5020,
    5050,
    5080,
    5110,
    5140,
    5170,
    5200,
  ];

  static List<FpvChannel> _buildBand(
    String bandName,
    List<int> freqs,
    BandCategory category,
  ) {
    return List.generate(
      freqs.length,
      (i) => FpvChannel(
        bandName: bandName,
        channelNumber: i + 1,
        frequency: freqs[i],
        category: category,
      ),
    );
  }

  static final List<FpvChannel> bandA = _buildBand(
    'A',
    bandAFrequencies,
    BandCategory.standard,
  );
  static final List<FpvChannel> bandB = _buildBand(
    'B',
    bandBFrequencies,
    BandCategory.standard,
  );
  static final List<FpvChannel> bandE = _buildBand(
    'E',
    bandEFrequencies,
    BandCategory.standard,
  );
  static final List<FpvChannel> bandF = _buildBand(
    'F',
    bandFFrequencies,
    BandCategory.standard,
  );
  static final List<FpvChannel> bandR = _buildBand(
    'R',
    bandRFrequencies,
    BandCategory.standard,
  );
  static final List<FpvChannel> bandL = _buildBand(
    'L',
    bandLFrequencies,
    BandCategory.lowband,
  );
  static final List<FpvChannel> bandX = _buildBand(
    'X',
    bandXFrequencies,
    BandCategory.xBand,
  );

  // Grouped lists
  static final List<FpvChannel> standardChannels = [
    ...bandR, // Raceband prioritised first for standard spacing
    ...bandF,
    ...bandA,
    ...bandB,
    ...bandE,
  ];

  static final List<FpvChannel> lowbandChannels = List.unmodifiable(bandL);
  static final List<FpvChannel> xBandChannels = List.unmodifiable(bandX);

  static final List<FpvChannel> allChannels = [
    ...standardChannels,
    ...lowbandChannels,
    ...xBandChannels,
  ];
}
