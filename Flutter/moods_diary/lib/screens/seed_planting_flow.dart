import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; 
// import '../models/emotion_tree_model.dart'; // Không cần thiết nếu đã có DTO
import '../services/emotion_tree_service.dart';

class SeedPlantingFlow extends StatefulWidget {
  final EmotionTreeService treeService;
  // Thay đổi kiểu dữ liệu callback: không cần truyền EmotionTree, chỉ cần thông báo hoàn tất.
  final VoidCallback onPlantingComplete; 
  final bool isWilted; 

  const SeedPlantingFlow({
    required this.treeService,
    required this.onPlantingComplete,
    this.isWilted = false,
    super.key
  });

  @override
  State<SeedPlantingFlow> createState() => _SeedPlantingFlowState();
}

class _SeedPlantingFlowState extends State<SeedPlantingFlow> {
  String? _selectedSeed = 'Hạnh phúc'; 
  bool _isPlanting = false;
  
  final List<String> _seedTypes = [
    'Hạnh phúc', 
    'Vui', 
    'Buồn', 
    'Tức giận', 
    'Đang yêu'
  ];

  // Hàm xử lý khi người dùng nhấn Bắt đầu Trồng/Hồi sinh
  Future<void> _handlePlanting() async {
    if (_selectedSeed == null) return;

    setState(() {
      _isPlanting = true; // Bắt đầu hiển thị Lottie
    });

    try {
      await Future.delayed(const Duration(seconds: 2)); 
      
      // Gọi hàm plantTree mới (trả về Future<void>)
      await widget.treeService.plantTree(seedType: _selectedSeed!);
      
      // Gọi callback, không cần truyền dữ liệu
      widget.onPlantingComplete(); 

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trồng cây thất bại: ${e.toString()}')),
        );
      }
      setState(() {
        _isPlanting = false; 
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Màn hình Lottie Animation (Khi đang trồng)
    if (_isPlanting) {
      return Scaffold(
        backgroundColor: Colors.lightGreen.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/seeds.json', 
                width: 400, 
                height: 400, 
                repeat: true, 
                reverse: false
              ),
              const SizedBox(height: 20),
              Text(
                widget.isWilted ? 'Đang hồi sinh cây...' : 'Đang trồng cây mới...',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    
    // Màn hình Chọn hạt giống/Trồng lại (Giữ nguyên)
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWilted ? 'Hồi Sinh Cây' : 'Gieo Hạt Giống'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isWilted 
                    ? 'Cây của bạn đã héo. Hãy chọn loại hạt giống mới để hồi sinh cây!'
                    : 'Đây là lần đầu bạn trồng cây. Hãy chọn loại hạt giống cảm xúc bạn muốn gieo.',
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              Image.asset(
                'assets/trees/dangyeu_gia.png', 
                height: 150,
              ),
              
              const SizedBox(height: 30),

              DropdownButtonFormField<String>(
                value: _selectedSeed,
                decoration: const InputDecoration(
                  labelText: 'Chọn loại Hạt giống Cảm xúc',
                  border: OutlineInputBorder(),
                ),
                items: _seedTypes.map((String seed) {
                  return DropdownMenuItem<String>(
                    value: seed,
                    child: Text(seed),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSeed = newValue;
                  });
                },
              ),
              
              const SizedBox(height: 50),
              
              ElevatedButton(
                onPressed: _selectedSeed != null ? _handlePlanting : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isWilted ? 'HỒI SINH CÂY' : 'BẮT ĐẦU TRỒNG CÂY',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
