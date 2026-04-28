import 'package:app/core/supabase_providers.dart';
import 'package:app/features/manage/data/account_model.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final manageViewModelProvider =
    ChangeNotifierProvider.autoDispose<ManageViewModel>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ManageViewModel(supabase: supabase);
});

class ManageException implements Exception {
  ManageException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ManageViewModel extends ChangeNotifier {
  ManageViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  String _categoryTypeFilter = 'expense';

  bool _loading = false;
  String? _loadError;

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  String get categoryTypeFilter => _categoryTypeFilter;
  bool get loading => _loading;
  String? get loadError => _loadError;

  List<CategoryModel> get filteredCategories {
    return _categories.where((c) => c.type == _categoryTypeFilter).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void setCategoryTypeFilter(String type) {
    if (type != 'expense' && type != 'income') return;
    if (_categoryTypeFilter == type) return;
    _categoryTypeFilter = type;
    notifyListeners();
  }

  Future<void> load() async {
    if (_supabase.auth.currentUser == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final accRes = await _supabase.from('accounts').select().order('name');
      final catRes = await _supabase.from('categories').select().order('name');
      _accounts = (accRes as List<dynamic>)
          .map((e) => AccountModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
      _categories = (catRes as List<dynamic>)
          .map((e) => CategoryModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String? _normalizeName(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return null;
    return n;
  }

  bool _accountNameTaken(String name, {String? exceptId}) {
    return _accounts.any(
      (a) => a.name == name && (exceptId == null || a.id != exceptId),
    );
  }

  bool _categoryNameTaken(String name, String type, {String? exceptId}) {
    return _categories.any(
      (c) =>
          c.name == name &&
          c.type == type &&
          (exceptId == null || c.id != exceptId),
    );
  }

  Future<void> addAccount(String rawName) async {
    final name = _normalizeName(rawName);
    if (name == null) throw ManageException('Tên tài khoản không được để trống');
    if (_accountNameTaken(name)) {
      throw ManageException('Đã có tài khoản cùng tên');
    }
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw ManageException('Chưa đăng nhập');
    await _supabase.from('accounts').insert({
      'user_id': uid,
      'name': name,
    });
    await load();
  }

  Future<void> renameAccount(String id, String rawName) async {
    final name = _normalizeName(rawName);
    if (name == null) throw ManageException('Tên tài khoản không được để trống');
    if (_accountNameTaken(name, exceptId: id)) {
      throw ManageException('Đã có tài khoản cùng tên');
    }
    await _supabase.from('accounts').update({'name': name}).eq('id', id);
    await load();
  }

  Future<void> deleteAccount(String id) async {
    await _supabase.from('accounts').delete().eq('id', id);
    await load();
  }

  Future<void> addCategory({
    required String rawName,
    required String type,
    String? color,
    String? icon,
  }) async {
    if (type != 'expense' && type != 'income') {
      throw ManageException('Loại danh mục không hợp lệ');
    }
    final name = _normalizeName(rawName);
    if (name == null) throw ManageException('Tên danh mục không được để trống');
    if (_categoryNameTaken(name, type)) {
      throw ManageException('Đã có danh mục cùng tên trong loại này');
    }
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw ManageException('Chưa đăng nhập');
    final c = (color == null || color.trim().isEmpty) ? _defaultColor(type) : color.trim();
    final ic = (icon == null || icon.trim().isEmpty) ? 'category' : icon.trim();
    await _supabase.from('categories').insert({
      'user_id': uid,
      'name': name,
      'type': type,
      'color': c,
      'icon': ic,
    });
    await load();
  }

  Future<void> updateCategory({
    required String id,
    required String rawName,
    required String type,
    String? color,
    String? icon,
  }) async {
    if (type != 'expense' && type != 'income') {
      throw ManageException('Loại danh mục không hợp lệ');
    }
    final name = _normalizeName(rawName);
    if (name == null) throw ManageException('Tên danh mục không được để trống');
    if (_categoryNameTaken(name, type, exceptId: id)) {
      throw ManageException('Đã có danh mục cùng tên trong loại này');
    }
    final c = (color == null || color.trim().isEmpty) ? _defaultColor(type) : color.trim();
    final ic = (icon == null || icon.trim().isEmpty) ? 'category' : icon.trim();
    await _supabase.from('categories').update({
      'name': name,
      'type': type,
      'color': c,
      'icon': ic,
    }).eq('id', id);
    await load();
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
    await load();
  }

  String _defaultColor(String type) =>
      type == 'income' ? '#26A69A' : '#78909C';
}
