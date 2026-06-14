import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../features/misc_cubits.dart';

class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({super.key});

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DesignsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('My Designs',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/editor'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: BlocBuilder<DesignsCubit, DesignsState>(
        builder: (context, state) {
          if (state is DesignsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DesignsLoaded) {
            if (state.designs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette_outlined,
                        size: 80, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    const Text('No designs yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Create your first design',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Start Designing',
                      onPressed: () => context.push('/editor'),
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: state.designs.length,
              itemBuilder: (context, index) {
                final design = state.designs[index];
                final isSelected =
                    state.selectedIds.contains(design.id);
                return FadeInUp(
                  delay: Duration(milliseconds: index * 80),
                  child: GestureDetector(
                    onTap: () => context.push('/editor'),
                    onLongPress: () =>
                        context
                            .read<DesignsCubit>()
                            .toggleSelection(design.id),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isSelected
                              ? BorderSide(
                                  color: AppColors.primary, width: 2)
                              : BorderSide.none),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: design.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(design.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(design.category,
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
