import 'package:flutter/material.dart';
import '../../../widgets/mediator_card.dart';
import '../../../utils/design_constants.dart';
import '../buyer_dashboard.dart';

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MediatorCard(
            icon: Icons.shopping_bag,
            title: 'Start Shopping',
            description: 'Explore our marketplace and find great deals',
            buttonText: 'Browse Products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BuyerDashboard()),
              );
            },
          ),
        ],
      ),
    );
  }
}
