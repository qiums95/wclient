import 'package:flutter/material.dart';
import 'package:wclient/ui/chat_list_page.dart';
import 'package:wclient/ui/contacts_page.dart';
import 'package:wclient/ui/profile_page.dart';

import 'package:wclient/ui/widgets/network_status_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MainAppBar(title: ['微信', '通讯录', '我的'][_currentIndex]),
        body: Column(
          children: [
            // 全局网络状态横幅
            const NetworkStatusBanner(),
            Expanded(
              child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    ChatListPage(),
                    ContactsPage(),
                    ProfilePage(),
                  ]
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (int index) {setState(() {_currentIndex = index;});},
        )
    );
  }
}

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFFEDEDED),
      elevation: 0,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: const Color(0xFF07C160),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            label: "微信",
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
          ),
          BottomNavigationBarItem(
            label: "通讯录",
            icon: Icon(Icons.perm_contact_calendar_outlined),
            activeIcon: Icon(Icons.perm_contact_calendar),
          ),
          BottomNavigationBarItem(
            label: "我的",
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
          ),
    ]);
  }
}