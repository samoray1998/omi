import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/pages/conversations/widgets/conversations_group_widget.dart';
import 'package:omi/pages/conversations/widgets/empty_conversations.dart';
import 'package:omi/pages/conversations/widgets/processing_capture.dart';
import 'package:omi/pages/conversations/widgets/search_result_header_widget.dart';
import 'package:omi/providers/conversation_provider.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/utils/other/debouncer.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/utils/styles.dart';
import 'package:omi/utils/ui_guidelines.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool showClearButton = false;

  void setShowClearButton() {
    if (showClearButton != _searchController.text.isNotEmpty) {
      setState(() {
        showClearButton = _searchController.text.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromRGBO(255, 249, 230, 1),
        child: Column(
          children: [
            SafeArea(
                child: Container(
              height: 50,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white),
              child: TextField(
                controller: _searchController,
                focusNode: context.read<HomeProvider>().convoSearchFieldFocusNode,
                onChanged: (value) {
                  var provider = Provider.of<ConversationProvider>(context, listen: false);
                  _debouncer.run(() async {
                    await provider.searchConversations(value);
                  });
                  setShowClearButton();
                },
                decoration: InputDecoration(
                  // hintText: 'Search Conversations',
                  // hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: TayaColors.secondaryTextColor,
                  ),
                  suffixIcon: showClearButton
                      ? Container(
                          margin: const EdgeInsets.all(8),

                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.grey),
                          child: GestureDetector(
                            onTap: () async {
                              var provider = Provider.of<ConversationProvider>(context, listen: false);
                              await provider.searchConversations(""); // clear
                              _searchController.clear();
                              setShowClearButton();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          //   ),
                          // ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                style: TextStyle(color: TayaColors.secondaryTextColor),
              ),
            )),
            Expanded(child: Consumer<ConversationProvider>(builder: (context, convoProvider, child) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // const SliverToBoxAdapter(child: SizedBox(height: 16)), // above capture widget
                  // const SliverToBoxAdapter(child: SpeechProfileCardWidget()),
                  // const SliverToBoxAdapter(child: UpdateFirmwareCardWidget()),
                  // // const SliverToBoxAdapter(child: ConversationCaptureWidget()),
                  // const SliverToBoxAdapter(child: SizedBox(height: 12)), // above search widget
                  // const SliverToBoxAdapter(
                  //   child: ConverstationsWidget(),
                  // ),
                  // const SliverToBoxAdapter(child: SizedBox(height: 0)),
                  // const SliverToBoxAdapter(child: SearchWidget()), //below search widget
                  const SliverToBoxAdapter(child: SearchResultHeaderWidget()),
                  getProcessingConversationsWidget(convoProvider.processingConversations),
                  if (convoProvider.groupedConversations.isEmpty && !convoProvider.isLoadingConversations)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32.0),
                          child: EmptyConversationsWidget(),
                        ),
                      ),
                    )
                  else if (convoProvider.groupedConversations.isEmpty && convoProvider.isLoadingConversations)
                    _buildLoadingShimmer()
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: convoProvider.groupedConversations.length + 1,
                        (context, index) {
                          if (index == convoProvider.groupedConversations.length) {
                            debugPrint('loading more conversations');
                            if (convoProvider.isLoadingConversations) {
                              return _buildLoadMoreShimmer();
                            }
                            // widget.loadMoreMemories(); // CALL this only when visible
                            return VisibilityDetector(
                              key: const Key('conversations-key'),
                              onVisibilityChanged: (visibilityInfo) {
                                var provider = Provider.of<ConversationProvider>(context, listen: false);
                                if (provider.previousQuery.isNotEmpty) {
                                  if (visibilityInfo.visibleFraction > 0 &&
                                      !provider.isLoadingConversations &&
                                      (provider.totalSearchPages > provider.currentSearchPage)) {
                                    provider.searchMoreConversations();
                                  }
                                } else {
                                  if (visibilityInfo.visibleFraction > 0 && !convoProvider.isLoadingConversations) {
                                    convoProvider.getMoreConversationsFromServer();
                                  }
                                }
                              },
                              child: const SizedBox(height: 20, width: double.maxFinite),
                            );
                          } else {
                            List<ServerConversation> ls =
                                convoProvider.groupedConversations.values.expand((v) => v).toList();
                            var now = DateTime.now();
                            var yesterday = now.subtract(const Duration(days: 1));

                            var isToday = (ls[index].startedAt?.month ?? ls[index].createdAt.month) == now.month &&
                                (ls[index].startedAt?.day ?? ls[index].createdAt.day) == now.day &&
                                (ls[index].startedAt?.year ?? ls[index].createdAt.year) == now.year;

                            var isYesterday =
                                (ls[index].startedAt?.month ?? ls[index].createdAt.month) == yesterday.month &&
                                    (ls[index].startedAt?.day ?? ls[index].createdAt.day) == yesterday.day &&
                                    (ls[index].startedAt?.year ?? ls[index].createdAt.year) == yesterday.year;
                            return ListView.separated(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(0),
                              itemBuilder: (contaxt, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 15),
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  width: double.infinity,
                                  decoration:
                                      BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 15,
                                            color: Color.fromRGBO(191, 185, 165, 1),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const Text(
                                            "Moments",
                                            style: TextStyle(color: Color.fromRGBO(191, 185, 165, 1)),
                                          ),
                                          Spacer(),
                                          Text(
                                            isToday
                                                ? 'Today' +
                                                    " " +
                                                    dateTimeFormat(
                                                      'h:mm a',
                                                      ls[index].startedAt ?? ls[index].createdAt,
                                                    )
                                                : isYesterday
                                                    ? 'Yesterday' +
                                                        " " +
                                                        dateTimeFormat(
                                                          'h:mm a',
                                                          ls[index].startedAt ?? ls[index].createdAt,
                                                        )
                                                    : dateTimeFormat(
                                                            'MMM dd', ls[index].startedAt ?? ls[index].createdAt) +
                                                        " " +
                                                        dateTimeFormat(
                                                          'h:mm a',
                                                          ls[index].startedAt ?? ls[index].createdAt,
                                                        ),
                                            style: const TextStyle(
                                                color: Color.fromRGBO(191, 185, 165, 1),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Container(
                                            child: const FaIcon(
                                              FontAwesomeIcons.arrowUpRightFromSquare,
                                              color: Color.fromRGBO(191, 185, 165, 1),
                                              size: 15,
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        width: double.infinity,
                                        child: Text(
                                          ls[index].structured.title,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                              color: TayaColors.secondaryTextColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 15),
                              itemCount: convoProvider.groupedConversations.values.expand((v) => v).toList().length,
                            );
                            // return Column(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     if (index == 0) const SizedBox(height: 10),
                            //     ConversationsGroupWidget(
                            //       isFirst: index == 0,
                            //       conversations: memoriesForDate,
                            //       date: date,
                            //     ),
                            //   ],
                            // );
                          }
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              );
            }))
          ],
        ),
      ),
    );
  }
}

Widget _buildLoadingShimmer() {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) => _buildConversationShimmer(),
      childCount: 3, // Show 3 shimmer conversation groups
    ),
  );
}

Widget _buildConversationShimmer() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header shimmer
        Shimmer.fromColors(
          baseColor: AppStyles.backgroundSecondary,
          highlightColor: AppStyles.backgroundTertiary,
          child: Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: AppStyles.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Conversation items shimmer
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Shimmer.fromColors(
                    baseColor: AppStyles.backgroundSecondary,
                    highlightColor: AppStyles.backgroundTertiary,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppStyles.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )),
      ],
    ),
  );
}

Widget _buildLoadMoreShimmer() {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Shimmer.fromColors(
      baseColor: AppStyles.backgroundSecondary,
      highlightColor: AppStyles.backgroundTertiary,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppStyles.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
