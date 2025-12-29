import 'package:flutter/material.dart';

class SafetyTipsCard extends StatefulWidget {
  const SafetyTipsCard({super.key});

  @override
  State<SafetyTipsCard> createState() => _SafetyTipsCardState();
}

class _SafetyTipsCardState extends State<SafetyTipsCard> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  static const List<SafetyTip> _safetyTips = [
    SafetyTip(
      icon: Icons.location_on,
      title: "Share Your Location",
      description: "Always let someone know where you're going and when you'll be back.",
      color: Colors.blue,
    ),
    SafetyTip(
      icon: Icons.phone,
      title: "Emergency Contacts",
      description: "Keep emergency numbers saved and easily accessible on your phone.",
      color: Colors.green,
    ),
    SafetyTip(
      icon: Icons.visibility,
      title: "Stay Alert",
      description: "Be aware of your surroundings, especially in unfamiliar areas.",
      color: Colors.orange,
    ),
    SafetyTip(
      icon: Icons.group,
      title: "Travel in Groups",
      description: "When possible, avoid walking alone, especially at night.",
      color: Colors.purple,
    ),
    SafetyTip(
      icon: Icons.lock,
      title: "Secure Valuables",
      description: "Don't display expensive items and keep belongings secure.",
      color: Colors.red,
    ),
    SafetyTip(
      icon: Icons.lightbulb,
      title: "Trust Your Instincts",
      description: "If something feels wrong, remove yourself from the situation.",
      color: Colors.amber,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tips_and_updates,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  "Safety Tips",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _safetyTips.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final tip = _safetyTips[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tip.color.withValues(alpha: 0.08),
                        tip.color.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: tip.color.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tip.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: tip.color.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              tip.icon,
                              color: tip.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tip.color.withValues(alpha: 0.9),
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          tip.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            height: 1.4,
                            fontSize: 13,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _safetyTips.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const SafetyTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
