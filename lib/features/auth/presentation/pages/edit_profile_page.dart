import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameCtrl = TextEditingController(text: user.name);
      _weightCtrl = TextEditingController(
          text: user.weightKg != null ? user.weightKg.toString() : '');
      _heightCtrl = TextEditingController(
          text: user.heightCm != null ? user.heightCm.toString() : '');
    } else {
      _nameCtrl = TextEditingController();
      _weightCtrl = TextEditingController();
      _heightCtrl = TextEditingController();
    }
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
    setState(() {
      _errorText = null;
      _isSaving = true;
    });
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            name: _nameCtrl.text.trim(),
            weightKg: double.tryParse(_weightCtrl.text.trim()),
            heightCm: double.tryParse(_heightCtrl.text.trim()),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DSSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back + Title row
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(DSRadius.sensorChip),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: DSColors.onDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Edit Profil',
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: DSColors.onDark,
                      letterSpacing: -0.01 * 22,
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                // Error
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DSColors.errorDark.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(DSRadius.control),
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
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Harus angka positif';
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
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Harus angka positif';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
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
                            'Simpan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Batal',
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
    );
  }
}
