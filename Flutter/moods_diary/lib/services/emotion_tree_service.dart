//moods_diary/lib/services/emotion_tree_service.dart
import 'package:flutter/foundation.dart';
import '../models/emotion_tree_model.dart';
import 'emotion_tree_api.dart';

class EmotionTreeService  extends ChangeNotifier{
  final EmotionTreeApi _api = EmotionTreeApi();

  EmotionTree? _treeData;
  EmotionTree? get treeData => _treeData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchTreeStatus() async {
    _isLoading = true;
    //notifyListeners();

    try {
      final treeModel = await _api.getTreeStatus();
      _treeData = treeModel;
    } catch (e) {
      print('Lỗi khi tải trạng thái cây: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // **Hàm trồng cây** (sử dụng EmotionTreeApi)
  Future<void> plantTree({required String seedType}) async {
    _isLoading = true;
    
    try {
      final treeModel = await _api.plantTree(seedType: seedType);
      _treeData = treeModel;
    } catch (e) {
      print('Lỗi khi trồng cây: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. API Ghi nhật ký (POST /api/tree/log)
  Future<void> logDiary({required String emotionType}) async {
    try {
      final result = await _api.logDiary(emotionType: emotionType);
      _treeData = result;
    } catch (e) {
      print('Lỗi khi ghi nhật ký: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  String _normalizeEmotionName(String emotion) {
    String normalized = emotion.toLowerCase();
      normalized = normalized
        .replaceAll(RegExp(r'[áàảãạăắằẳẵặâấầẩẫậ]'), 'a')
        .replaceAll(RegExp(r'[éèẻẽẹêếềểễệ]'), 'e')
        .replaceAll(RegExp(r'[íìỉĩị]'), 'i')
        .replaceAll(RegExp(r'[óòỏõọôốồổỗộơớờởỡợ]'), 'o')
        .replaceAll(RegExp(r'[úùủũụưứừửữự]'), 'u')
        .replaceAll(RegExp(r'[ýỳỷỹỵ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd');
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized; 
  }

  String getTreeImage(EmotionTree data) {
    String status;
    if (data.level == 0 || data.needsPlanting) {
      return 'assets/animations/seeds.png';
    } else if (data.daysSinceLastEntry >= 7) {
      return 'assets/trees/cayheo.png';
    } else if (data.level == 1) {
      status = 'con';
    } else if (data.level == 2) {
      status = 'truongthanh';
    } else {
      status = 'gia';
    }

    String emotionPrefix = _normalizeEmotionName(data.emotionDominance);
    if (emotionPrefix.isEmpty) {
      emotionPrefix = 'default';
    }

    return 'assets/trees/${emotionPrefix}_$status.png';
  }
}
