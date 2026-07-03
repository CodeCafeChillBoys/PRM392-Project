import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/category_option.dart';
import '../../../data/services/product_service.dart';
import '../../widgets/widgets.dart';

/// Form Staff thêm sản phẩm mới (`POST /api/Products`, body khớp
/// CreateProductDTO). Pop `true` khi tạo thành công để danh sách reload.
/// BE sau khi tạo tự broadcast notification "Siêu phẩm mới" cho mọi máy.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _service = ProductService();

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _imageCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<CategoryOption> _categories = [];
  CategoryOption? _category;
  bool _loadingCategories = true;
  bool _submitting = false;

  /// key field → thông điệp lỗi, hiện dưới field; xoá khi user gõ lại.
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await _service.fetchCategoryOptions();
      if (mounted) setState(() => _categories = list);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được danh mục.');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickCategory() async {
    // Lỡ lần đầu lỗi mạng → bấm lại ô danh mục sẽ thử tải lại.
    if (_categories.isEmpty) {
      await _loadCategories();
      if (_categories.isEmpty) return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<CategoryOption>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn danh mục', style: AppText.h3()),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = _categories[i];
                    return TvOptionRow(
                      title: c.name,
                      icon: const TvIcon('tag'),
                      selected: _category?.id == c.id,
                      onTap: () => Navigator.of(sheetContext).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _category = picked;
        _errors.remove('category');
      });
    }
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) {
      errors['name'] = 'Vui lòng nhập tên sản phẩm.';
    }
    if (_brandCtrl.text.trim().isEmpty) {
      errors['brand'] = 'Vui lòng nhập hãng sản xuất.';
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      errors['price'] = 'Giá phải là số lớn hơn 0.';
    }
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (stock == null || stock < 0) {
      errors['stock'] = 'Tồn kho là số nguyên ≥ 0.';
    }
    if (_category == null) {
      errors['category'] = 'Vui lòng chọn danh mục.';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    try {
      await _service.createProduct(
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        stockQuantity: int.parse(_stockCtrl.text.trim()),
        categoryId: _category!.id,
        categoryName: _category!.name,
        imageUrl: _imageCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        TvToast.show(context, 'Thêm sản phẩm thất bại. Thử lại nhé.');
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageCtrl.text.trim();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            title: 'Thêm sản phẩm',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    label: 'Tên sản phẩm *',
                    errorKey: 'name',
                    child: TvInput(
                      controller: _nameCtrl,
                      hintText: 'VD: iPhone 15 Pro Max',
                      onChanged: (_) => _clearError('name'),
                    ),
                  ),
                  _field(
                    label: 'Hãng sản xuất *',
                    errorKey: 'brand',
                    child: TvInput(
                      controller: _brandCtrl,
                      hintText: 'VD: Apple',
                      onChanged: (_) => _clearError('brand'),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Giá (đ) *',
                          errorKey: 'price',
                          child: TvInput(
                            controller: _priceCtrl,
                            hintText: 'VD: 34990000',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _clearError('price'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: 'Tồn kho',
                          errorKey: 'stock',
                          child: TvInput(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _clearError('stock'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _field(
                    label: 'Danh mục *',
                    errorKey: 'category',
                    child: _categoryPicker(),
                  ),
                  _field(
                    label: 'Ảnh (URL)',
                    errorKey: 'image',
                    child: TvInput(
                      controller: _imageCtrl,
                      hintText: 'https://...',
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: ProductImage(url: imageUrl),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _field(
                    label: 'Mô tả',
                    errorKey: 'description',
                    child: TvInput(
                      controller: _descCtrl,
                      hintText: 'Thông số nổi bật, điểm bán hàng...',
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TvButton(
                    label: 'Thêm sản phẩm',
                    fullWidth: true,
                    loading: _submitting,
                    leadingIcon: const TvIcon('plus', size: 16),
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nhãn + ô nhập + dòng lỗi (nếu có) — khung chung cho mọi trường.
  Widget _field({
    required String label,
    required String errorKey,
    required Widget child,
  }) {
    final error = _errors[errorKey];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label()),
          const SizedBox(height: 6),
          child,
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error, style: AppText.xs(AppColors.danger500)),
          ],
        ],
      ),
    );
  }

  /// Ô chọn danh mục — nhìn như TvInput, bấm mở bottom sheet.
  Widget _categoryPicker() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _loadingCategories ? null : _pickCategory,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _category?.name ??
                    (_loadingCategories ? 'Đang tải danh mục...' : 'Chọn danh mục'),
                style: _category == null
                    ? AppText.body(AppColors.textTertiary)
                    : AppText.body(),
              ),
            ),
            if (_loadingCategories)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              )
            else
              const TvIcon('chevron-down', color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
