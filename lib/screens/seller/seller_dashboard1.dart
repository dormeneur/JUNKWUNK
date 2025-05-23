import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../main.dart' as main_app;
import 'mediator/page1.dart';
import 'mediator/page2.dart';
import 'mediator/page3.dart';

class SellerDashboard1 extends StatefulWidget {
  const SellerDashboard1({super.key});

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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple[700]!,
                  Colors.deepPurple[900]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.5),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.deepPurple[900],
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          main_app.handleLogout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade400,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
