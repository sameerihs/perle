import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/wallpaper_repository.dart';
import 'explore_page.dart';
import 'liked_page.dart';
import 'search_page.dart';
import 'wallpaper_controller.dart';

class WallpaperShell extends StatefulWidget {
  const WallpaperShell({super.key, required this.repository});

  final WallpaperRepository repository;

  @override
  State<WallpaperShell> createState() => _WallpaperShellState();
}

class _WallpaperShellState extends State<WallpaperShell> {
  late final WallpaperController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = WallpaperController(widget.repository);
    unawaited(_controller.loadFeatured());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ExplorePage(controller: _controller),
      SearchPage(controller: _controller),
      LikedPage(controller: _controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Likes',
          ),
        ],
      ),
    );
  }
}
