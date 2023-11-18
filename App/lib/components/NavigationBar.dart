import 'package:flutter/material.dart';
import 'package:test_clique_connect/main.dart'; // Import your main file to access MyApp.blueMain
import 'package:test_clique_connect/components/AnimatedMarkersMap_NEW.dart';
import '../pages/home_page.dart';
import 'Calendar.dart';
import 'Home.dart';

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({Key? key}) : super(key: key);

  @override
  _BottomNavigationBarExampleState createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _getBodyForIndex(_selectedIndex),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGradientShadow(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 120, // Set your desired height
        child: ResponsiveNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Image.asset(
                'icons/home_grey.png',
                width: 25,
                height: 25,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'icons/chat_all_grey.png',
                width: 25,
                height: 25,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'icons/calendar_grey.png',
                width: 25,
                height: 25,
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'icons/map_color.png',
                width: 25,
                height: 25,
              ),
              label: 'Map',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return HomePageChat();
      case 2:
        return CalendarScreen();
      case 3:
        return const AnimatedMarkersMap_NEW();
      default:
        return Container();
    }
  }

  Widget _buildGradientShadow() {
    return Container(
      height: kBottomNavigationBarHeight, // Set to the height of the navigation bar
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.black12,
// Adjust the color as needed
          ],
        ),
      ),
    );
  }
}

class ResponsiveNavigationBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ResponsiveNavigationBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Small screen, show only icons
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      items: items.map((item) {
        return _buildItem(item, items.indexOf(item) == currentIndex);
      }).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: MyApp.blueMain,
    );
  }

  BottomNavigationBarItem _buildItem(
      BottomNavigationBarItem item, bool isSelected) {
    if (items.indexOf(item) == currentIndex) {
      return BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? MyApp.blueMain : null,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.white : Colors.grey,
              BlendMode.srcIn,
            ),
            child: item.icon,
          ),
        ),
        label: item.label,
      );
    } else {
      return item;
    }
  }
}
