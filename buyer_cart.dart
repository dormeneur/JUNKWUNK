import 'package:flutter/material.dart';

class BuyerCart extends StatefulWidget {
  @override
  _BuyerCartState createState() => _BuyerCartState();
}

class _BuyerCartState extends State<BuyerCart> with TickerProviderStateMixin {
  Set<int> selectedItems = {};
  bool isSelectionMode = false;
  List<int> cartItems = List.generate(4, (index) => index); // To track available items

  final Map<int, AnimationController> _checkboxAnimationControllers = {};
  final Map<int, AnimationController> _slideAnimationControllers = {};
  final Map<int, AnimationController> _deleteAnimationControllers = {};

  @override
  void dispose() {
    _checkboxAnimationControllers.values.forEach((controller) => controller.dispose());
    _slideAnimationControllers.values.forEach((controller) => controller.dispose());
    _deleteAnimationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  AnimationController _getCheckboxAnimationController(int index) {
    if (!_checkboxAnimationControllers.containsKey(index)) {
      _checkboxAnimationControllers[index] = AnimationController(
        duration: Duration(milliseconds: 200), // Faster animation
        vsync: this,
      );
    }
    return _checkboxAnimationControllers[index]!;
  }

  AnimationController _getSlideAnimationController(int index) {
    if (!_slideAnimationControllers.containsKey(index)) {
      _slideAnimationControllers[index] = AnimationController(
        duration: Duration(milliseconds: 200), // Faster animation
        vsync: this,
      );
    }
    return _slideAnimationControllers[index]!;
  }

  AnimationController _getDeleteAnimationController(int index) {
    if (!_deleteAnimationControllers.containsKey(index)) {
      _deleteAnimationControllers[index] = AnimationController(
        duration: Duration(milliseconds: 200), // Faster animation
        vsync: this,
      );
    }
    return _deleteAnimationControllers[index]!;
  }

  void _deleteSelectedItems() {
    for (var item in selectedItems) {
      _removeItem(item);
    }
  }

  void _removeItem(int index) {
    final controller = _getDeleteAnimationController(index);
    controller.forward().then((_) {
      setState(() {
        cartItems.remove(index);
        selectedItems.remove(index);
        if (selectedItems.isEmpty) {
          isSelectionMode = false;
        }
      });
      controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buyer'),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: selectedItems.isNotEmpty ? _deleteSelectedItems : null,
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedItems.clear();
                  _checkboxAnimationControllers.values.forEach((controller) => controller.reverse());
                  _slideAnimationControllers.values.forEach((controller) => controller.reverse());
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text('Cart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _categoryButton('Donation', 3),
              _categoryButton('Recycle', 8),
              _categoryButton('Non Recycle', 2),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _cartItem(cartItems[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('you have ${cartItems.length} items in cart, continue to place order'),
                ElevatedButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text('Check out'),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _categoryButton(String title, int count) {
    return ElevatedButton(
      onPressed: () {},
      child: Row(
        children: [
          Text(title),
          SizedBox(width: 5),
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.green,
            child: Text('$count', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(int index) {
    bool isSelected = selectedItems.contains(index);
    final checkboxAnimationController = _getCheckboxAnimationController(index);
    final slideAnimationController = _getSlideAnimationController(index);
    final deleteAnimationController = _getDeleteAnimationController(index);

    final Animation<Offset> checkboxSlideAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: checkboxAnimationController,
      curve: Curves.easeOut,
    ));

    final Animation<Offset> contentSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: slideAnimationController,
      curve: Curves.easeOut,
    ));

    final Animation<Offset> deleteSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: deleteAnimationController,
      curve: Curves.easeOut,
    ));

    return GestureDetector(
      onLongPress: () {
        setState(() {
          if (!isSelectionMode) {
            isSelectionMode = true;
            selectedItems.add(index);
            checkboxAnimationController.forward();
            slideAnimationController.forward();
          }
        });
      },
      child: SlideTransition(
        position: deleteSlideAnimation,
        child: Card(
          margin: EdgeInsets.all(10),
          color: isSelected ? Colors.grey[200] : null,
          child: Stack(
            children: [
              SlideTransition(
                position: contentSlideAnimation,
                child: ListTile(
                  title: Text('Customer name'),
                  subtitle: Text('I have Newspapers and other stuff'),
                  onTap: isSelectionMode
                      ? () {
                          setState(() {
                            if (isSelected) {
                              selectedItems.remove(index);
                              slideAnimationController.reverse();
                              checkboxAnimationController.reverse();
                              if (selectedItems.isEmpty) {
                                isSelectionMode = false;
                              }
                            } else {
                              selectedItems.add(index);
                              checkboxAnimationController.forward();
                              slideAnimationController.forward();
                            }
                          });
                        }
                      : null,
                ),
              ),
              if (isSelectionMode && isSelected)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: checkboxSlideAnimation,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                          color: Colors.blue,
                        ),
                        child: Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
