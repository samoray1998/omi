import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/utils/styles.dart';

class PersistentSwipeActions extends StatefulWidget {
  final Widget child;
  //final Widget conversation;
  //final int conversationIdx;
  //final String date;
  final VoidCallback onChat;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const PersistentSwipeActions({
    Key? key,
    required this.child,
    //required this.conversation,
    //required this.conversationIdx,
    // required this.date,
    required this.onChat,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  }) : super(key: key);

  @override
  _PersistentSwipeActionsState createState() => _PersistentSwipeActionsState();
}

class _PersistentSwipeActionsState extends State<PersistentSwipeActions> with TickerProviderStateMixin {
  double _dragExtent = 0;
  bool _isActionsVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _actionButtonWidth = 70.0; // Width for each action button
  static const double _maxLeftSwipeExtent = 210.0; // 3 buttons * 70 width
  static const double _maxRightSwipeExtent = 70.0; // 1 delete button
  static const double _swipeThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;

      // Constrain drag extent
      if (_dragExtent > _maxLeftSwipeExtent) {
        _dragExtent = _maxLeftSwipeExtent;
      } else if (_dragExtent < -_maxRightSwipeExtent) {
        _dragExtent = -_maxRightSwipeExtent;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // Determine if we should show actions or snap back
    if (_dragExtent.abs() > _swipeThreshold) {
      // Show actions persistently
      setState(() {
        _isActionsVisible = true;
        if (_dragExtent > 0) {
          _dragExtent = _maxLeftSwipeExtent;
        } else {
          _dragExtent = -_maxRightSwipeExtent;
        }
      });
      _animationController.forward();
    } else {
      // Snap back to original position
      _hideActions();
    }
  }

  void _hideActions() {
    setState(() {
      _isActionsVisible = false;
      _dragExtent = 0;
    });
    _animationController.reverse();
  }

  void _handleActionTap(VoidCallback action) {
    // Execute the action
    action();
    // Hide the actions after selection
    _hideActions();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Close actions when tapping elsewhere
      onTap: _isActionsVisible ? _hideActions : null,
      child: Container(
        child: Stack(
          children: [
            // Left actions (Chat, Edit, Share)
            if (_dragExtent > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragExtent.clamp(0.0, _maxLeftSwipeExtent),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // Chat Action
                      if (_dragExtent > 20)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: GestureDetector(
                                  onTap: () => _handleActionTap(widget.onChat),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: TayaColors.secondaryTextColor,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    alignment: Alignment.center,
                                    child: SvgPicture.asset(
                                      "assets/images/MsgSparkle.svg",
                                      height: 20.0,
                                      width: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Edit Action
                      if (_dragExtent > 90)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: GestureDetector(
                                  onTap: () => _handleActionTap(widget.onEdit),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(7, 107, 139, 1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    alignment: Alignment.center,
                                    child: SvgPicture.asset(
                                      "assets/images/PenSparkle.svg",
                                      height: 20.0,
                                      width: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Share Action
                      if (_dragExtent > 160)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: GestureDetector(
                                  onTap: () => _handleActionTap(widget.onShare),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(82, 185, 202, 1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    alignment: Alignment.center,
                                    child: SvgPicture.asset(
                                      "assets/images/ShareLeft.svg",
                                      height: 20.0,
                                      width: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Right action (Delete)
            if (_dragExtent < 0)
              Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: (-_dragExtent).clamp(0.0, _maxRightSwipeExtent),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 15,
                      ),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: GestureDetector(
                          onTap: () => _handleActionTap(widget.onDelete),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.trashCan,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),

            // Main content
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
