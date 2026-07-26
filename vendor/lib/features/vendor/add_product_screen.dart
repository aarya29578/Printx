import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/category_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

// Same endpoint used by Admin Panel
const _kProductUploadUrl =
    'https://jenishaonlineservice.com/printx/api/upload-banner.php';

// ─── Screen (Add or Edit mode) ────────────────────────────────────────────────

class AddProductScreen extends StatefulWidget {
  /// Pass [productId] to open in edit mode.
  final String? productId;
  const AddProductScreen({super.key, this.productId});

  bool get isEditMode => productId != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizesController = TextEditingController();
  final _finishesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _minQtyController = TextEditingController(text: '1');

  final ImagePicker _picker = ImagePicker();

  // New files selected from device
  final List<File> _newImages = [];
  // Existing image URLs (edit mode only)
  List<String> _existingImageUrls = [];

  List<Category> _categories = [];
  Category? _selectedCategory;

  String _statusValue = 'active';
  bool _isFeatured = false;
  bool _isNewArrival = false;
  bool _isSaving = false;
  bool _isLoading = true;

  // Edit mode: original product's vendorId (for permission check)
  String? _originalVendorId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final catFuture = FirestoreService.fetchCategories();

    if (widget.isEditMode) {
      final results = await Future.wait([
        catFuture,
        FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId!)
            .get(),
      ]);
      final cats = results[0] as List<Category>;
      final snap = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      if (!mounted) return;

      if (snap.exists) {
        _prefillFromDocument(snap.data()!, cats);
      }
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } else {
      final cats = await catFuture;
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  void _prefillFromDocument(Map<String, dynamic> data, List<Category> cats) {
    _originalVendorId = data['vendorId'] as String?;
    _nameController.text = (data['name'] as String?) ?? '';
    _descController.text = (data['description'] as String?) ?? '';
    _priceController.text =
        ((data['basePrice'] as num?)?.toInt() ?? 0).toString();
    _minQtyController.text =
        ((data['minQty'] as num?)?.toInt() ?? 1).toString();

    // Sizes / finishes / tags — stored as array or CSV in Firestore
    _sizesController.text = _joinList(data['sizes']);
    _finishesController.text = _joinList(data['finishes']);
    _tagsController.text = _joinList(data['tags']);

    _statusValue = (data['status'] as String?) ?? 'active';
    _isFeatured =
        data['featured'] == true || data['isBestseller'] == true;
    _isNewArrival = data['isNew'] == true;

    // Existing image URLs
    final imgUrl = data['imageUrl'] as String?;
    final imgUrls = data['imageUrls'];
    if (imgUrls is List && imgUrls.isNotEmpty) {
      _existingImageUrls = imgUrls.cast<String>();
    } else if (imgUrl != null && imgUrl.isNotEmpty) {
      _existingImageUrls = [imgUrl];
    }

    // Match category by ID
    final catId = data['category'] as String?;
    if (catId != null) {
      try {
        _selectedCategory =
            cats.firstWhere((c) => c.id == catId);
      } catch (_) {}
    }
  }

  String _joinList(dynamic value) {
    if (value is List) return value.join(', ');
    if (value is String) return value;
    return '';
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      for (final xf in picked) {
        if (_totalImageCount < 5) _newImages.add(File(xf.path));
      }
    });
  }

  Future<void> _pickImageFromCamera() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (_totalImageCount < 5) _newImages.add(File(picked.path));
    });
  }

  int get _totalImageCount =>
      _existingImageUrls.length + _newImages.length;

  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));
  void _removeNewImage(int index) =>
      setState(() => _newImages.removeAt(index));

  Future<String?> _uploadOneImage(File file, String bannerId) async {
    try {
      final formData = dio.FormData.fromMap({
        'bannerId': bannerId,
        'image': await dio.MultipartFile.fromFile(
          file.path,
          filename: 'product_$bannerId.jpg',
        ),
      });
      final response = await dio.Dio().post(_kProductUploadUrl, data: formData);
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Product image upload error: $e');
    }
    return null;
  }

  Future<List<String>> _uploadNewImages(String productId) async {
    final urls = <String>[];
    for (int i = 0; i < _newImages.length; i++) {
      final bannerId =
          _existingImageUrls.isEmpty && i == 0 ? productId : '${productId}_${_existingImageUrls.length + i}';
      final url = await _uploadOneImage(_newImages[i], bannerId);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  List<String> _splitCsv(String value) => value
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      AppToast.show(context, 'Please select a category',
          type: ToastType.error);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AppToast.show(context, 'You must be logged in', type: ToastType.error);
      return;
    }
    final vendorId = authState.userId;
    final vendorName = authState.name;
    final vendorEmail = authState.email;

    // Permission check: vendor may only edit their own products
    if (widget.isEditMode &&
        _originalVendorId != null &&
        _originalVendorId != vendorId) {
      AppToast.show(context, 'You can only edit your own products',
          type: ToastType.error);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = int.tryParse(_priceController.text.trim()) ?? 0;
      final minQty = int.tryParse(_minQtyController.text.trim()) ?? 1;

      if (widget.isEditMode) {
        // ── Edit mode: update existing document ──────────────────────────
        final productId = widget.productId!;

        // Upload any new images
        final newUrls = await _uploadNewImages(productId);
        final allUrls = [..._existingImageUrls, ...newUrls];

        final data = <String, dynamic>{
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'category': _selectedCategory!.id,
          'basePrice': price,
          'originalPrice': price,
          'sizes': _splitCsv(_sizesController.text),
          'finishes': _splitCsv(_finishesController.text),
          'minQty': minQty,
          'quantities': minQty > 0 ? [minQty] : [],
          'tags': _splitCsv(_tagsController.text),
          'featured': _isFeatured,
          'isBestseller': _isFeatured,
          'isNew': _isNewArrival,
          'status': _statusValue,
          if (allUrls.isNotEmpty) 'imageUrl': allUrls.first,
          if (allUrls.isNotEmpty) 'imageUrls': allUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirestoreService.updateProduct(
            productId: productId, data: data);

        if (!mounted) return;
        AppToast.show(context, 'Product updated!', type: ToastType.success);
        context.pop();
      } else {
        // ── Add mode: create new document ────────────────────────────────
        final productId = 'PRD${DateTime.now().millisecondsSinceEpoch}';
        final categoryId = _selectedCategory!.id;

        List<String> imageUrls = [];
        if (_newImages.isNotEmpty) {
          imageUrls = await _uploadNewImages(productId);
        }

        final data = <String, dynamic>{
          'id': productId,
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'category': categoryId,
          'basePrice': price,
          'originalPrice': price,
          'sku': 'SKU-$productId',
          'imageUrl': imageUrls.isNotEmpty
              ? imageUrls.first
              : 'https://picsum.photos/seed/new-product/400/300',
          'imageUrls': imageUrls,
          'sizes': _splitCsv(_sizesController.text),
          'finishes': _splitCsv(_finishesController.text),
          'quantities': minQty > 0 ? [minQty] : [],
          'minQty': minQty,
          'tags': _splitCsv(_tagsController.text),
          'featured': _isFeatured,
          'isBestseller': _isFeatured,
          'isNew': _isNewArrival,
          'status': _statusValue,
          'stock': 'in_stock',
          'rating': 0,
          'reviewCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
          'vendorId': vendorId,
          'vendorName': vendorName,
          'vendorEmail': vendorEmail,
          'createdBy': 'vendor',
          'createdByRole': 'vendor',
        };

        final db = FirebaseFirestore.instance;
        await db.collection('products').doc(productId).set(data);
        await db.collection('categories').doc(categoryId).update({
          'productCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        AppToast.show(context, 'Product published!', type: ToastType.success);
        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _sizesController.clear();
    _finishesController.clear();
    _tagsController.clear();
    _minQtyController.text = '1';
    setState(() {
      _newImages.clear();
      _existingImageUrls.clear();
      _selectedCategory = null;
      _statusValue = 'active';
      _isFeatured = false;
      _isNewArrival = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _sizesController.dispose();
    _finishesController.dispose();
    _tagsController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final title =
        widget.isEditMode ? 'Edit Product' : 'Add Product';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: widget.isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (!_isSaving && !widget.isEditMode)
            TextButton(onPressed: _resetForm, child: const Text('Reset')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              color: cardColor,
              title: 'Product Images',
              child: _buildImagePicker(),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              color: cardColor,
              title: 'Product Information',
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Product Name',
                    hint: 'e.g. Premium Business Cards',
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _descController,
                    label: 'Description',
                    hint: 'Describe your product...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              color: cardColor,
              title: 'Pricing',
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      label: 'Price per unit (₹)',
                      hint: '0',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if ((int.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _minQtyController,
                      label: 'Min Quantity',
                      hint: '1',
                      prefixIcon: Icons.shopping_bag_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              color: cardColor,
              title: 'Specifications',
              child: Column(
                children: [
                  AppTextField(
                    controller: _sizesController,
                    label: 'Sizes (comma separated)',
                    hint: 'e.g. A4, A5, 4x6 inch',
                    prefixIcon: Icons.straighten_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _finishesController,
                    label: 'Finishes (comma separated)',
                    hint: 'e.g. Matte, Glossy, Spot UV',
                    prefixIcon: Icons.layers_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _tagsController,
                    label: 'Tags (comma separated)',
                    hint: 'e.g. business, print, card',
                    prefixIcon: Icons.label_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              color: cardColor,
              title: 'Status & Visibility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusDropdown(),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Featured'),
                    value: _isFeatured,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('New Arrival'),
                    value: _isNewArrival,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    onChanged: (v) => setState(() => _isNewArrival = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _isSaving
                  ? 'Saving...'
                  : widget.isEditMode
                      ? 'Update Product'
                      : 'Publish Product',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusValue,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.toggle_on_outlined,
            size: 20, color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'draft', child: Text('Draft')),
        DropdownMenuItem(value: 'paused', child: Text('Paused')),
      ],
      onChanged: (v) => setState(() => _statusValue = v ?? 'active'),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_isLoading) {
      return const SizedBox(
          height: 56, child: Center(child: LinearProgressIndicator()));
    }
    return DropdownButtonFormField<Category>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined,
            size: 20, color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      hint: const Text('Select Category'),
      isExpanded: true,
      items: _categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (cat) => setState(() => _selectedCategory = cat),
      validator: (_) =>
          _selectedCategory == null ? 'Please select a category' : null,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing image URLs (edit mode)
        if (_existingImageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _existingImageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(index),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('Cover',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // New images from device
        if (_newImages.isNotEmpty) ...[
          if (_existingImageUrls.isNotEmpty) const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_newImages[index],
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(index),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('New',
                            style: TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        if (_totalImageCount > 0) const SizedBox(height: 12),

        if (_totalImageCount < 5)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          _totalImageCount == 0
              ? 'Add up to 5 images. First image is the cover.'
              : '$_totalImageCount/5 images.',
          style:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Helper widget ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
