import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reliability Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ReliabilityCalculator(),
    );
  }
}

class ReliabilityCalculator extends StatefulWidget {
  const ReliabilityCalculator({super.key});

  @override
  State<ReliabilityCalculator> createState() => _ReliabilityCalculatorState();
}

class _ReliabilityCalculatorState extends State<ReliabilityCalculator> {
  final TextEditingController _connectionController = TextEditingController(text: "6");
  final TextEditingController _accidentPriceController = TextEditingController(text: "23.6");
  final TextEditingController _planedPriceController = TextEditingController(text: "17.6");

  CalculationResult? _calculationResult;

  @override
  void dispose() {
    _connectionController.dispose();
    _accidentPriceController.dispose();
    _planedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reliability Calculator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: _connectionController,
                decoration: const InputDecoration(
                  labelText: 'Підключення (n)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _accidentPriceController,
                decoration: const InputDecoration(
                  labelText: 'Ціна аварії (ac_price)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _planedPriceController,
                decoration: const InputDecoration(
                  labelText: 'Планова ціна (pl_price)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _calculationResult = calculateReliability(
                        double.tryParse(_connectionController.text) ?? 6,
                        double.tryParse(_accidentPriceController.text) ?? 23.6,
                        double.tryParse(_planedPriceController.text) ?? 17.6,
                      );
                    });
                  },
                  child: const Text('Розрахувати'),
                ),
              ),

              const SizedBox(height: 16),

              if (_calculationResult != null) _buildResultCard(_calculationResult!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(CalculationResult result) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow("Частота відмов (W_oc)", result.wOc),
            _buildResultRow("Середній час відновлення (t_v_oc)", result.tvOc, "рік^-1"),
            _buildResultRow("Коефіцієнт аварійного простою (k_a_oc)", result.kaOc, "год"),
            _buildResultRow("Коефіцієнт планового простою (k_p_oc)", result.kpOc),
            _buildResultRow("Частота відмов (W_dk)", result.wDk, "рік^-1"),
            _buildResultRow("Частота відмов з урахуванням вимикача (W_dc)", result.wDc, "рік^-1"),
            const Text("Математичні сподівання:", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildResultRow("аварійних поломок (math_W_ned_a)", result.mathWNedA, "кВт*год"),
            _buildResultRow("планових поломок (math_W_ned_p)", result.mathWNedP, "кВт*год"),
            _buildResultRow("збитків (math_loses)", result.mathLoses, "грн"),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double value, [String unit = ""]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              softWrap: true,
            ),
          ),
          Expanded(
            child: Text(
              "${value.toStringAsFixed(4)} $unit",
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class CalculationResult {
  final double wOc;
  final double tvOc;
  final double kaOc;
  final double kpOc;
  final double wDk;
  final double wDc;
  final double mathWNedA;
  final double mathWNedP;
  final double mathLoses;

  CalculationResult({
    required this.wOc,
    required this.tvOc,
    required this.kaOc,
    required this.kpOc,
    required this.wDk,
    required this.wDc,
    required this.mathWNedA,
    required this.mathWNedP,
    required this.mathLoses,
  });
}

CalculationResult calculateReliability(
    double n,
    double accidentPrice,
    double planedPrice,
    ) {
  double wOc = 0.01 + 0.07 + 0.015 + 0.02 + 0.03 * n;
  double tvOc = (0.01 * 30 + 0.07 * 10 + 0.015 * 100 + 0.02 * 15 + (0.03 * n) * 2) / wOc;
  double kaOc = (wOc * tvOc) / 8760;
  double kpOc = 1.2 * (43 / 8760);
  double wDk = 2 * wOc * (kaOc + kpOc);
  double wDc = wDk + 0.02;

  double mathWNedA = 0.01 * 45 * pow(10, -3) * 5.12 * pow(10, 3) * 6451;
  double mathWNedP = 4 * pow(10, 3) * 5.12 * pow(10, 3) * 6451;
  double mathLoses = accidentPrice * mathWNedA + planedPrice * mathWNedP;

  return CalculationResult(
    wOc: wOc,
    tvOc: tvOc,
    kaOc: kaOc,
    kpOc: kpOc,
    wDk: wDk,
    wDc: wDc,
    mathWNedA: mathWNedA,
    mathWNedP: mathWNedP,
    mathLoses: mathLoses,
  );
}