import 'package:flutter/material.dart';
// Import the login model
// Import the login model


class CustomBottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final dynamic loginResponseModel; // Add loginResponseModel or any other data you need

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    this.loginResponseModel,  // Add this for passing data
  });

  @override
  CustomBottomNavbarState createState() => CustomBottomNavbarState();
}

class CustomBottomNavbarState extends State<CustomBottomNavbar> {

  // Handle bottom nav bar tap logic here
  void _onItemTapped(int index) {
    if (index == 0) {
      // Show a message for the first tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This page is in progress'),
        ),
      );
    } else if (index == 1) {
      // Navigate to HomeScreen
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => HomeScreen(
      //       loginResponseModel: widget.loginResponseModel, // Pass the data here
      //     ),
      //   ),
      // );
    } else if (index == 2) {
      // Navigate to CallScreen

    }

    // If you want to update the bottom navigation index state here, use the passed onItemTapped callback
    widget.onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        height: 63, // Adjusted height to reduce overall size
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomRight,
            colors: [
              Color(0x00D6D6D6), // Transparent
              Color(0xFFADB2BD), // Solid color
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0), // Add padding to align vertically
                child: Image.asset(
                  'assets/png/icons/message.png',
                  color: const Color(0xFF151544),
                  height: 20, // Adjust icon size
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0), // Add padding to align vertically
                child: Image.asset(
                  'assets/png/icons/home.png',
                  color: const Color(0xFF151544),
                  height: 20, // Adjust icon size
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0), // Add padding to align vertically
                child: Image.asset(
                  'assets/png/icons/phone.png',
                  color: const Color(0xFF151544),
                  height: 20, // Adjust icon size
                ),
              ),
              label: '',
            ),
          ],
          currentIndex: widget.currentIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          iconSize: 25, // Adjust overall icon size
          onTap: _onItemTapped, // Call the internal function to handle taps
        ),
      ),
    );
  }
}
