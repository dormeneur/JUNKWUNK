import 'package:flutter/material.dart';
import '../../../widgets/mediator_card.dart';
import '../../../utils/design_constants.dart';
import '../../profile/profile_page.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MediatorCard(
            icon: Icons.person,
            title: 'Profile Settings',
            description: 'Manage your profile and preferences',
            buttonText: 'View Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileUI()),
              );
            },
          ),
        ],
      ),
    );
  }
}
