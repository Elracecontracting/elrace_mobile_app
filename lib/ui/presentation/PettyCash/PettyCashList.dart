import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import '../../widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';

class PettyCashList extends StatefulWidget {
  final dynamic loginResponseModel;

  PettyCashList({required this.loginResponseModel});

  @override
  _PettyCashListState createState() => _PettyCashListState();
}

class _PettyCashListState extends State<PettyCashList> {
  double _position = 0.0;
  bool _submitted = false;

  void _handleSubmit() {
    if (_submitted) return; // Prevent multiple submissions

    setState(() {
      _submitted = true;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Submitted Successfully!")),
    );

    // Reset the slider after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _position = 0.0;
        _submitted = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width - 60; // Adjust width

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const HeaderWidget(),


          // ✅ Petty Cash Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'PETTY CASH',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appFontColor),
                ),
                Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: appFontColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PettyCashPopUpScreen(loginResponseModel: widget.loginResponseModel),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),


          // ✅ Expense List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
                  child: Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/png/item_bg.png'), // Make sure the path is correct
                        fit: BoxFit.contain, // Makes the image cover the entire container
                      ),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((2 * 255).toInt()),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(25, 9, 15, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Submitted",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: appFontColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 5),

                          SizedBox(
                            height: 30,
                            child: VerticalDivider(
                              color: Colors.grey,
                              thickness: 2,
                            ),
                          ),
                          SizedBox(width: 5),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appFontColor,
                                  ),
                                ),
                                Text(
                                  "03/03/2025",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: appFontColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 30,
                            child: VerticalDivider(
                              color: Colors.grey,
                              thickness: 2,
                            ),
                          ),
                          SizedBox(width: 5),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appFontColor,
                                  ),
                                ),
                                Text(
                                  "3,000",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 0),
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: AssetImage('assets/png/tick-petty.png'),
                          ),
                          SizedBox(width: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
