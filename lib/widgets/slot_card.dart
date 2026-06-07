import 'package:flutter/material.dart';

class SlotCard extends StatelessWidget {
  final int slotNumber;
  final bool isOccupied;

  const SlotCard({
    super.key,
    required this.slotNumber,
    required this.isOccupied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOccupied ? Colors.red[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOccupied ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOccupied ? Icons.directions_car : Icons.local_parking,
            size: 40,
            color: isOccupied ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            'Chỗ $slotNumber',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            isOccupied ? 'Có xe' : 'Trống',
            style: TextStyle(
              color: isOccupied ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
