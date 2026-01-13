import 'package:flutter/material.dart';
// ignore: unused_import
import '../models/emotion_tree_model.dart';
import '../services/emotion_tree_service.dart';
import 'seed_planting_flow.dart';
import '../widgets/animated_tree.dart';

class EmotionTreeScreen extends StatefulWidget {
  final EmotionTreeService treeService;
  final EmotionTree? initialTree;
  final bool canGoBack;

  const EmotionTreeScreen({
    required this.treeService,
    this.initialTree,
    this.canGoBack = true,
    super.key,
  });

  @override
  State<EmotionTreeScreen> createState() => _EmotionTreeScreenState();
}

class _EmotionTreeScreenState extends State<EmotionTreeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.treeService.addListener(_handleTreeUpdate);

    if (widget.treeService.treeData != null) {
      _isLoading = false;
    } else {
      _fetchTreeStatus();
    }
  }

  @override
  void dispose() {
    widget.treeService.removeListener(_handleTreeUpdate);
    super.dispose();
  }

  void _handleTreeUpdate() {
    if (mounted) {
      setState(() {
        _isLoading = widget.treeService.isLoading;
      });
    }
  }

  Future<void> _fetchTreeStatus() async {
    if (!mounted) return;
    try {
      await widget.treeService.fetchTreeStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải trạng thái cây: ${e.toString()}')),
        );
      }
    }
  }

  void _onPlantingComplete() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cây cảm xúc đã được trồng thành công!')),
      );
    }
  }

  Widget _buildGrowthBar(EmotionTree tree) {
    const maxPoints = 7;
    final progress = tree.growthPoint / maxPoints;

    //Lấy tên cây trực tiếp từ dữ liệu và level
    final levelName = tree.level <= 1
        ? 'con'
        : tree.level == 2
            ? 'trưởng thành'
            : 'già';
    // Sử dụng emotionDominance trực tiếp từ API
    final treeName = 'Cây ${tree.emotionDominance.toLowerCase()} $levelName';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Text(
            treeName, // Tên cây
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${tree.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${tree.growthPoint}/$maxPoints điểm', style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),

          // Thanh tiến trình
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 254, 248, 247),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0), // Đảm bảo trong khoảng 0-1
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink, // Màu thanh progress mới
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Cảm xúc gần nhất: ${tree.emotionType}',
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Trong _EmotionTreeScreenState (File EmotionTreeScreen.dart)

void _showWaterTasks() {
  final EmotionTree? treeData = widget.treeService.treeData;
  // Giả sử service đã tải dữ liệu. Nếu chưa tải, list sẽ rỗng.
  final List<WaterTask> tasks = treeData?.waterTasks ?? []; 
  debugPrint('Số lượng nhiệm vụ nước: ${tasks.length}');

  if (tasks.isEmpty) {
    if (treeData == null || treeData.needsPlanting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trồng hoặc trồng lại cây trước.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nhiệm vụ tưới nước nào đang hoạt động.')),
      );
    }
    return; // Dừng hàm, không hiển thị modal
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Thêm nước tưới",
              style: TextStyle(
                fontSize: 22,
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // SỬ DỤNG DANH SÁCH NHIỆM VỤ THỰC TẾ
            ...tasks.map((task) => _task(
              task.title,
              task.progress,
              task.reward,
              task.isDone,
            )),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      );
    },
  );
}

  Widget _task(String title, String progress, String reward, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? Colors.pink.shade50 : Colors.white,
        border: Border.all(color: Colors.pink.shade100),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text("$title ($progress)")),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDone ? Colors.pink.shade300 : Colors.pinkAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(reward, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildTreeDisplay(EmotionTree tree) {
    final treeAsset = widget.treeService.getTreeImage(tree);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: widget.canGoBack,
        title: const Text(
          'Trang cây cảm xúc',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Ảnh nền (theo yêu cầu)
          Positioned.fill(
            child: Image.asset(
              'assets/trees/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.lightGreen);
              },
            ),
          ),

          // 2. Icon thông báo và Nông trại bạn bè (Như trong ảnh)
          Positioned(
            top: 60,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.notifications_none, size: 30, color: Colors.white),
                const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                const Icon(Icons.group, size: 30, color: Colors.red),
                const Text('Nông trại bạn bè', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),

          // 3. Nội dung chính (Cây và Thanh progress)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // HIỂN THỊ CẢNH BÁO CÂY HÉO
                if (tree.daysSinceLastEntry >= 7)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Cây đang bị héo do chưa ghi nhật ký!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // END HIỂN THỊ CẢNH BÁO

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100, bottom: 0),
                    child: AnimatedTree(
                      treeAssetPath: treeAsset, 
                      emotionDominance: tree.emotionDominance,
                    ),
                  ),
                ),
                // Thanh tăng trưởng + Tên cây
                _buildGrowthBar(tree),

                const SizedBox(height: 20),

                // NÚT THÊM NƯỚC TƯỚI
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: ElevatedButton(
                    onPressed: _showWaterTasks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Thêm nước tưới',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.treeService.treeData;

    if (_isLoading || (tree == null && widget.treeService.isLoading)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (tree == null || tree.needsPlanting) {
      return SeedPlantingFlow(
        treeService: widget.treeService,
        onPlantingComplete: _onPlantingComplete,
        isWilted: tree != null && tree.level > 0,
      );
    }

    return _buildTreeDisplay(tree);
  }
}