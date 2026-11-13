import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/kunjungan.dart';
import 'status_chip.dart';

/// Kartu satu kunjungan pada daftar
class KunjunganCard extends StatelessWidget {
  final Kunjungan data;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const KunjunganCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = data.tanggalDateTime;
    final tgl = tanggal == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(tanggal);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person_outline, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.namaPelanggan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  StatusChip(data.status),
                  PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? onEdit() : onHapus(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data.alamat,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, size: 14),
                            const SizedBox(width: 4),
                            Text(data.noHp,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14),
                            const SizedBox(width: 4),
                            Text(tgl, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (data.punyaKoordinat)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, size: 14),
                              SizedBox(width: 4),
                              Text('GPS tersimpan',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
