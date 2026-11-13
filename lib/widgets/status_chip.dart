import 'package:flutter/material.dart';

Color warnaStatus(String status) {
  switch (status) {
    case 'Selesai':
      return Colors.green;
    case 'Batal':
      return Colors.red;
    default:
      return Colors.orange;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: warna,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
