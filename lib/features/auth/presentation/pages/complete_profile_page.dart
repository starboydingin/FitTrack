import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/auth_provider.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  final String initialName;

  const CompleteProfilePage({super.key, required this.initialName});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorText = null);
    try {
      await ref.read(authStateProvider.notifier).completeProfile(
            name: _nameCtrl.text.trim(),
            weightKg: double.parse(_weightCtrl.text.trim()),
            heightCm: double.parse(_heightCtrl.text.trim()),
          );
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DSSpacing.page),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glass icon container
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DSRadius.frame),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(DSRadius.frame),
                            border: Border.all(
                              color: DSColors.primaryDark.withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_add_outlined,
                                size: 36, color: DSColors.primaryDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Lengkapi Profil',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: DSColors.onDark,
                      letterSpacing: -0.01 * 22,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'Data ini digunakan untuk estimasi aktivitas Anda',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: DSColors.onDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error
                  if (_errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DSColors.errorDark.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(DSRadius.control),
                        border: Border.all(
                            color: DSColors.errorDark.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: DSColors.errorDark, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: DSColors.errorDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DSColors.onDark),
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DSColors.onDark),
                    decoration: const InputDecoration(
                      labelText: 'Berat Badan (kg)',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Berat badan wajib diisi';
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0)
                        return 'Harus angka positif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Height
                  TextFormField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DSColors.onDark),
                    decoration: const InputDecoration(
                      labelText: 'Tinggi Badan (cm)',
                      prefixIcon: Icon(Icons.height_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Tinggi badan wajib diisi';
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0)
                        return 'Harus angka positif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSave,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    DSColors.onPrimaryDark),
                              ),
                            )
                          : Text(
                              'Simpan Profil',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
