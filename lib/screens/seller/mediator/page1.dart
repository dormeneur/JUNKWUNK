import 'package:flutter/material.dart';
import '../../../widgets/mediator_card.dart';
import '../../../utils/design_constants.dart';
import '../seller_dashboard.dart';

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
            icon: Icons.add_shopping_cart,
            title: 'List a New Item',
            description: 'Start selling by adding your product details',
            buttonText: 'Get Started',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SellerDashboard()),
              );
            },
          ),
        ],
      ),
    );
  }
}
