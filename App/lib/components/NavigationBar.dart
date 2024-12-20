import 'package:flutter/material.dart';
import 'package:test_clique_connect/main.dart';
import 'package:test_clique_connect/components/AnimatedMarkersMap_NEW.dart';
import '../pages/home_page.dart';
import 'Calendar.dart';
import 'EventHome.dart';

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({Key? key}) : super(key: key);

  @override
  _BottomNavigationBarExampleState createState() => _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage('icons/home_white.png'),context);
    precacheImage(const AssetImage('icons/chat_all_white.png'),context);
    precacheImage(const AssetImage('icons/calendar_white.png'),context);
    precacheImage(const AssetImage('icons/map_white.png'),context);
    super.didChangeDependencies();
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
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, 'icons/home_grey.png','icons/home_white.png'),
            _buildNavItem(1, 'icons/chat_all_grey.png','icons/chat_all_white.png'),
            _buildNavItem(2, 'icons/calendar_grey.png','icons/calendar_white.png'),
            _buildNavItem(3, 'icons/map_color.png','icons/map_white.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconData, String iconDataHover) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: _selectedIndex == 0 || _selectedIndex == 3 ? MediaQuery.of(context).size.width*0.25 : 80,
        height: _selectedIndex == 0 || _selectedIndex == 3 ? 100 : 80,
        decoration: BoxDecoration(
          color: _selectedIndex == index ? MyApp.blueMain : Colors.transparent,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Center(
          child: Image.asset(
            _selectedIndex == index ? iconDataHover : iconData,
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}

  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 0:
        return const EventHome();
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
      height: 16,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black12,
          ],
        ),
      ),
    );
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
