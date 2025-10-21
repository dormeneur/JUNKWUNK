import 'package:flutter/material.dart';
import '../../../widgets/mediator_card.dart';
import '../../../utils/design_constants.dart';
import '../buyer_cart.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MediatorCard(
            icon: Icons.shopping_cart,
            title: 'Your Cart',
            description: 'View and manage items in your shopping cart',
            buttonText: 'View Cart',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BuyerCart()),
              );
            },
          ),
        ],
      ),
    );
  }
}
