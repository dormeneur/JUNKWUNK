import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'mediator/page1.dart';
import 'mediator/page2.dart';
import 'mediator/page3.dart';

class SellerDashboard1 extends StatefulWidget {
  @override
  _SellerDashboard1State createState() => _SellerDashboard1State();
}

class _SellerDashboard1State extends State<SellerDashboard1> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[900]!,
              Colors.deepPurple[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    Page1(),
                    Page2(),
                    Page3(),
                  ],
                ),
              ),
              _buildPageIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Seller Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Welcome back!",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: JumpingDotEffect(
              activeDotColor: Colors.white,
              dotColor: Colors.white.withOpacity(0.2),
              dotHeight: 18,
              dotWidth: 18,
              spacing: 12,
            ),
          ),
        ],
      ),
    );
  }
}
