import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/aqi_provider.dart';

class LiveStatusBar extends StatelessWidget {
  const LiveStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final aqi = context.watch<AqiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (aqi.status) {
      case ConnectionStateStatus.connected:
        statusColor = const Color(0xFF10B981);
        statusText = 'Render Live';
        statusIcon = Icons.cloud_done_rounded;
        break;
      case ConnectionStateStatus.connecting:
        statusColor = const Color(0xFF06B6D4);
        statusText = 'Syncing...';
        statusIcon = Icons.sync_rounded;
        break;
      case ConnectionStateStatus.mock:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Simulation';
        statusIcon = Icons.memory_rounded;
        break;
      case ConnectionStateStatus.error:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Offline / Retrying';
        statusIcon = Icons.cloud_off_rounded;
        break;
      case ConnectionStateStatus.initial:
        statusColor = Colors.grey;
        statusText = 'Initializing';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final formattedTime = aqi.lastSyncedTime != null
        ? DateFormat('hh:mm:ss a').format(aqi.lastSyncedTime!)
        : 'Never';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Status indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Last Sync Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Updated: $formattedTime',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              if (aqi.isPollingActive)
                Text(
                  'Next refresh in ${aqi.countdown}s',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                )
              else
                const Text(
                  'Auto-refresh paused',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Play / Pause Polling Button
          InkWell(
            onTap: () => aqi.togglePolling(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                aqi.isPollingActive
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Manual Refresh Button
          InkWell(
            onTap: () => aqi.refreshData(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
