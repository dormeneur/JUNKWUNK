import 'package:flutter/material.dart';
import '../../../widgets/mediator_card.dart';
import '../../../utils/design_constants.dart';
import '../summary_page.dart';

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
            icon: Icons.inventory_2,
            title: 'View Listed Items',
            description: 'Check and manage your listed products',
            buttonText: 'View All',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SummaryPage.viewAll()),
              );
            },
          ),
        ],
      ),
    );
  }
}
