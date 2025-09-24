import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/pages/chat/page.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/styles.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        // filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.only(
            left: 15,
            right: 15,
            top: 5,
            bottom: 15, // Extra bottom padding for safe area
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: "assets/images/Sparkles.svg",
                          label: 'Moments',
                          index: 0,
                          isSelected: widget.selectedIndex == 0,
                        ),
                        _buildNavItem(
                          icon: "assets/images/Feather.svg",
                          label: 'Journal',
                          index: 1,
                          isSelected: widget.selectedIndex == 1,
                        ),
                        _buildNavItem(
                          icon: "assets/images/ClockClockwise.svg",
                          label: 'Memories',
                          index: 2,
                          isSelected: widget.selectedIndex == 2,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                _buildProfileAvatar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              color: isSelected ? TayaColors.primaryTextColor : TayaColors.secondaryTextColor,
              semanticsLabel: 'Red dash paths',
            ),
            // Icon(
            //   icon,
            //   color: isSelected ? TayaColors.primaryTextColor : TayaColors.secondaryTextColor,
            //   size: 20,
            // ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? TayaColors.primaryTextColor : TayaColors.secondaryTextColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        MixpanelManager().bottomNavigationTabClicked('Chat');
        // Navigate to chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatPage(isPivotBottom: false),
          ),
        );
      }, // Profile index
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Color.fromRGBO(70, 175, 193, 1),
          shape: BoxShape.circle,
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          height: 20,
          width: 20,
          child: SvgPicture.asset(
            "assets/images/MsgBubbles.svg",
            color: Colors.white,
            semanticsLabel: 'Red dash paths',
          ),
        ),
        //child: const Icon(
        //   FontAwesomeIcons.comments,
        //   color: Colors.white,
        //   size: 25,
        // ),
      ),
    );
  }
}
