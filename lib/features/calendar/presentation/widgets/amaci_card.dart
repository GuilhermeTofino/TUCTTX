import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmaciCard extends StatefulWidget {
  final DateTime? nextAmaciDate;

  const AmaciCard({super.key, required this.nextAmaciDate});

  @override
  State<AmaciCard> createState() => _AmaciCardState();
}

class _AmaciCardState extends State<AmaciCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.nextAmaciDate == null ||
        widget.nextAmaciDate!.isBefore(DateTime.now())) {
      return const SizedBox.shrink();
    }

    final dateStr = DateFormat("dd/MM/yyyy").format(widget.nextAmaciDate!);
    final daysRemaining = widget.nextAmaciDate!
        .difference(DateTime.now())
        .inDays;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: _isExpanded
                ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _isExpanded ? 24 : 12,
              offset: Offset(0, _isExpanded ? 12 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Watermark Icon
              if (_isExpanded)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(_isExpanded ? 24 : 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildAnimatedIcon(),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMainInfo(dateStr)),
                        _buildChevron(),
                      ],
                    ),
                    _buildExpandedContent(daysRemaining),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isExpanded ? Colors.white.withOpacity(0.2) : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isExpanded
            ? []
            : [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        Icons.water_drop_rounded,
        color: _isExpanded ? Colors.white : Colors.blue[700],
        size: 26,
      ),
    );
  }

  Widget _buildMainInfo(String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRÓXIMO AMACI",
          style: TextStyle(
            color: _isExpanded
                ? Colors.white.withOpacity(0.8)
                : Colors.grey[500],
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: TextStyle(
            color: _isExpanded ? Colors.white : Colors.blue[900],
            fontWeight: FontWeight.w800,
            fontSize: _isExpanded ? 22 : 19,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChevron() {
    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isExpanded
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _isExpanded ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(int daysRemaining) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(height: 0),
      secondChild: Column(
        children: [
          const SizedBox(height: 24),
          divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  "Tempo",
                  daysRemaining == 0 ? "É HOJE!" : "$daysRemaining dias",
                  Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailCard(
                  "Presença",
                  "Confirmada",
                  Icons.verified_user_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInstructionBanner(),
        ],
      ),
      crossFadeState: _isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget divider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Prepare suas roupas brancas e suas guias.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
