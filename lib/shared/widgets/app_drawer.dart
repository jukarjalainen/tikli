import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF57BF32)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tikli',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              selected: currentRoute == AppRoutes.speciesList,
              leading: const Icon(Icons.list_alt),
              title: const Text('Lisää havainto'),
              onTap: () {
                if (currentRoute != AppRoutes.speciesList) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.speciesList);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              selected: currentRoute == AppRoutes.observationList,
              leading: const Icon(Icons.location_pin),
              title: const Text('Pinnat'),
              onTap: () {
                if (currentRoute != AppRoutes.observationList) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.observationList);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
