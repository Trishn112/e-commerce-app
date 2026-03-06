import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  // Message list now supports an optional 'product' key
  final List<Map<String, dynamic>> _messages = [
    {
      "message": "Hello Trish! I'm your ShopFuture AI assistant. How can I help you find the perfect product today?",
      "isUser": false,
      "time": "Just now",
      "product": null,
    },
  ];

  final List<String> _suggestions = [
    "Track my order",
    "Current discounts?",
    "Best headphones",
    "Shipping info"
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? text}) {
    final messageText = text ?? _controller.text;
    if (messageText.trim().isEmpty) return;

    setState(() {
      _messages.add({
        "message": messageText,
        "isUser": true,
        "time": _getCurrentTime(),
        "product": null,
      });
      _isTyping = true;
    });

    if (text == null) _controller.clear();
    _scrollToBottom();

    // AI Simulated Response Logic
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      String botReply = "I'm not sure about that, but check out this top-rated item!";
      Map<String, dynamic>? productData;
      String query = messageText.toLowerCase();
      
      // Logic to inject products based on keywords
      if (query.contains("track") || query.contains("order")) {
        botReply = "Your last order #PS9921 is currently in transit and expected to arrive this Friday!";
      } else if (query.contains("discount") || query.contains("promo")) {
        botReply = "Use code PREMIUM10 at checkout to get 10% off!";
      } else if (query.contains("headphone") || query.contains("audio")) {
        botReply = "The 'AudioPro Wireless v2' is currently our most recommended pair!";
        productData = {
          "name": "AudioPro Wireless v2",
          "price": "299.99",
          "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500",
        };
      } else if (query.contains("shipping")) {
        botReply = "We offer free Express Shipping on all orders over \$50.";
      }

      setState(() {
        _isTyping = false;
        _messages.add({
          "message": botReply,
          "isUser": false,
          "time": _getCurrentTime(),
          "product": productData,
        });
      });
      _scrollToBottom();
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ShopFuture AI", 
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_isTyping ? "Typing..." : "Online assistant", 
                  style: TextStyle(color: _isTyping ? AppColors.primary : Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                return _ChatBubble(
                  message: chat["message"],
                  isUser: chat["isUser"],
                  time: chat["time"],
                  product: chat["product"],
                );
              },
            ),
          ),

          if (_isTyping) _buildTypingIndicator(),

          // Suggestions Row
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 10),
                  child: ActionChip(
                    label: Text(_suggestions[index]),
                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    onPressed: () => _sendMessage(text: _suggestions[index]),
                  ),
                );
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text("ShopFuture is thinking...", 
          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12, 
        bottom: MediaQuery.of(context).padding.bottom + 12
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Ask ShopFuture AI...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 24,
              child: Icon(Icons.mic_none_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;
  final Map<String, dynamic>? product;

  const _ChatBubble({
    required this.message, 
    required this.isUser, 
    required this.time,
    this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              boxShadow: [
                if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          
          if (product != null) _buildProductCard(context),

          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(product!['image'], height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("\$${product!['price']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("View Details", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}