import 'package:app/core/supabase_providers.dart';
import 'package:app/features/transactions/data/transaction_receipt_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final transactionReceiptsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<TransactionReceiptsViewModel, String>((ref, transactionId) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionReceiptsViewModel(
    supabase: supabase,
    transactionId: transactionId,
  );
});

class TransactionReceiptsException implements Exception {
  TransactionReceiptsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ReceiptItem {
  const ReceiptItem({
    required this.model,
    required this.signedUrl,
  });

  final TransactionReceiptModel model;
  final String signedUrl;
}

class TransactionReceiptsViewModel extends ChangeNotifier {
  TransactionReceiptsViewModel({
    required SupabaseClient supabase,
    required String transactionId,
  })  : _supabase = supabase,
        _transactionId = transactionId;

  final SupabaseClient _supabase;
  final String _transactionId;

  bool _loading = false;
  String? _error;
  List<ReceiptItem> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<ReceiptItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _supabase
          .from('transaction_receipts')
          .select('id, transaction_id, path, created_at')
          .eq('transaction_id', _transactionId)
          .order('created_at', ascending: false);
      final models = (res as List<dynamic>)
          .map((e) => TransactionReceiptModel.fromRow(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      final out = <ReceiptItem>[];
      for (final m in models) {
        final url = await _supabase.storage
            .from('receipts')
            .createSignedUrl(m.path, 60 * 30);
        out.add(ReceiptItem(model: m, signedUrl: url));
      }
      _items = out;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUpload() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw TransactionReceiptsException('Chưa đăng nhập');

    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    final ext = _extFromName(xfile.name);
    final objectName = '$uid/$_transactionId/${const Uuid().v4()}.$ext';

    await _uploadBytes(objectName, bytes, contentType: _contentTypeForExt(ext));

    await _supabase.from('transaction_receipts').insert({
      'user_id': uid,
      'transaction_id': _transactionId,
      'path': objectName,
    });

    await load();
  }

  Future<void> deleteReceipt(TransactionReceiptModel r) async {
    await _supabase.storage.from('receipts').remove([r.path]);
    await _supabase.from('transaction_receipts').delete().eq('id', r.id);
    await load();
  }

  Future<void> _uploadBytes(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    await _supabase.storage.from('receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );
  }

  String _extFromName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return 'jpg';
    final ext = name.substring(i + 1).toLowerCase();
    if (ext == 'jpeg' || ext == 'jpg' || ext == 'png' || ext == 'webp') return ext;
    return 'jpg';
  }

  String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}

