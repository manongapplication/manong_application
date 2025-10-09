import 'package:flutter/material.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/sub_service_card.dart';

class SubServiceListScreen extends StatefulWidget {
  final ServiceItem serviceItem;
  final Color? iconColor;

  const SubServiceListScreen({
    super.key,
    required this.serviceItem,
    this.iconColor,
  });

  @override
  State<SubServiceListScreen> createState() => _SubServiceListScreenState();
}

class _SubServiceListScreenState extends State<SubServiceListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceItem = widget.serviceItem;
    final iconColor = widget.iconColor ?? Colors.black;
    final List<SubServiceItem> subServiceItems =
        widget.serviceItem.subServiceItems ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: myAppBar(title: 'Services'),
      body: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconCard(iconColor: iconColor, iconName: serviceItem.iconName),
                SizedBox(width: 8),
                Text(
                  serviceItem.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            SizedBox(height: 14),

            Expanded(
              child: subServiceItems.isEmpty
                  ? Center(child: Text("No services available"))
                  : SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Choose a service that fits your needs:',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 14),

                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                itemCount: subServiceItems.length + 1,
                                controller: _scrollController,
                                itemBuilder: (context, index) {
                                  if (index == subServiceItems.length) {
                                    return InkWell(
                                      onTap: () {
                                        // Navigator.pushNamed(
                                        //   context,
                                        //   '/problem-details',
                                        //   arguments: {
                                        //     'serviceItem': serviceItem,
                                        //     'iconColor': iconColor,
                                        //   },
                                        // );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.build_circle_outlined,
                                              color: iconColor,
                                              size: 31,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Upcoming Services',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Stay Tuned for More Services!',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            // Icon(
                                            //   Icons.arrow_forward_ios,
                                            //   color: Colors.grey.shade600,
                                            // ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final subServiceItem = subServiceItems[index];

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: SubServiceCard(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/problem-details',
                                          arguments: {
                                            'serviceItem': serviceItem,
                                            'subServiceItem': subServiceItem,
                                            'iconColor': iconColor,
                                          },
                                        );
                                      },
                                      subServiceItem: subServiceItem,
                                      iconColor: iconColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
