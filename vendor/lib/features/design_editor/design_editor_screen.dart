import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';

class DesignEditorScreen extends StatefulWidget {
  const DesignEditorScreen({super.key});

  @override
  State<DesignEditorScreen> createState() => _DesignEditorScreenState();
}

class _DesignEditorScreenState extends State<DesignEditorScreen> {
  String _selectedTool = 'text';
  Color _selectedColor = AppColors.primary;
  double _fontSize = 24.0;
  final List<_DesignElement> _elements = [];
  final TextEditingController _textCtrl = TextEditingController();

  static const _colors = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Colors.black,
    Colors.white,
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _addText() {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() {
      _elements.add(_DesignElement(
        type: 'text',
        content: _textCtrl.text.trim(),
        color: _selectedColor,
        fontSize: _fontSize,
        x: 100,
        y: 100 + (_elements.length * 40.0),
      ));
      _textCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Design Editor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => context.push('/preview'),
            child: const Text('Preview'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      painter: _GridPainter(),
                      child: const SizedBox.expand(),
                    ),
                    // Design elements
                    ..._elements.map((el) => Positioned(
                          left: el.x,
                          top: el.y,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              setState(() {
                                el.x += d.delta.dx;
                                el.y += d.delta.dy;
                              });
                            },
                            child: Text(
                              el.content,
                              style: TextStyle(
                                color: el.color,
                                fontSize: el.fontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )),
                    if (_elements.isEmpty)
                      const Center(
                        child: Text(
                          'Start designing!\nAdd text or shapes below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Tools Panel
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ToolButton(
                      icon: Icons.text_fields_rounded,
                      label: 'Text',
                      isSelected: _selectedTool == 'text',
                      onTap: () => setState(() => _selectedTool = 'text'),
                    ),
                    _ToolButton(
                      icon: Icons.format_shapes_rounded,
                      label: 'Shape',
                      isSelected: _selectedTool == 'shape',
                      onTap: () => setState(() => _selectedTool = 'shape'),
                    ),
                    _ToolButton(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      isSelected: _selectedTool == 'image',
                      onTap: () => setState(() => _selectedTool = 'image'),
                    ),
                    _ToolButton(
                      icon: Icons.color_lens_outlined,
                      label: 'Color',
                      isSelected: _selectedTool == 'color',
                      onTap: () => setState(() => _selectedTool = 'color'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                if (_selectedTool == 'text') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type something...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: _addText,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Text('Size: ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 10,
                          max: 60,
                          divisions: 10,
                          label: _fontSize.round().toString(),
                          onChanged: (v) =>
                              setState(() => _fontSize = v),
                        ),
                      ),
                    ],
                  ),
                ],

                // Color palette
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (_, i) {
                      final isSelected = _selectedColor == _colors[i];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = _colors[i]),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _colors[i],
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 2.5,
                                  )
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignElement {
  final String type;
  final String content;
  final Color color;
  final double fontSize;
  double x;
  double y;

  _DesignElement({
    required this.type,
    required this.content,
    required this.color,
    required this.fontSize,
    required this.x,
    required this.y,
  });
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
