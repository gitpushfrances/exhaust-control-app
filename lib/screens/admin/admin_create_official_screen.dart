import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class AdminCreateOfficialScreen extends StatefulWidget {
  const AdminCreateOfficialScreen({super.key});

  @override
  State<AdminCreateOfficialScreen> createState() =>
      _AdminCreateOfficialScreenState();
}

class _AdminCreateOfficialScreenState extends State<AdminCreateOfficialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirestoreService _fs = FirestoreService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  List<String> _municipalities = [];
  String? _selectedMunicipality;
  List<Map<String, dynamic>> _barangays = [];
  Map<String, dynamic>? _selectedBarangay;
  bool _loadingMunicipalities = true;
  bool _loadingBarangays = false;

  AppUser? _existingOfficial;
  bool _loadingExisting = false;

  @override
  void initState() {
    super.initState();
    _loadMunicipalities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMunicipalities() async {
    setState(() => _loadingMunicipalities = true);
    final list = await _fs.getMunicipalities();
    if (!mounted) return;
    setState(() {
      _municipalities = list;
      _loadingMunicipalities = false;
    });
  }

  Future<void> _onMunicipalityChanged(String? value) async {
    if (value == null) return;
    setState(() {
      _selectedMunicipality = value;
      _selectedBarangay = null;
      _existingOfficial = null;
      _barangays = [];
      _loadingBarangays = true;
    });
    final barangays = await _fs.getBarangaysByMunicipality(value);
    if (!mounted) return;
    setState(() {
      _barangays = barangays;
      _loadingBarangays = false;
    });
  }

  Future<void> _onBarangayChanged(Map<String, dynamic>? value) async {
    if (value == null) return;
    setState(() {
      _selectedBarangay = value;
      _existingOfficial = null;
      _loadingExisting = true;
    });
    final official = await _fs.getOfficialByBarangayId(value['doc_id']);
    if (!mounted) return;
    setState(() {
      _existingOfficial = official;
      _loadingExisting = false;
    });
  }

  Future<void> _createOfficial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBarangay == null) {
      _showError('Please select a barangay.');
      return;
    }

    if (_existingOfficial != null) {
      final confirmed = await _showOverrideDialog();
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);
    final adminUser = context.read<app_auth.AuthProvider>().user;
    final adminUid = adminUser?.uid ?? '';

    try {
      final barangayId = _selectedBarangay!['doc_id'] as String;
      final barangayName = _selectedBarangay!['barangay_name'] as String;

      // Use secondary Firebase app to avoid signing out admin
      final secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = fb_auth.FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await secondaryApp.delete();

      final uid = cred.user!.uid;

      // ── Write user doc + sync occupancy to barangay doc ──────
      await _fs.createOfficialAccountWithSync(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        barangayId: barangayId,
        barangayName: barangayName,
        createdByUid: adminUid,
      );

      // If replacing, deactivate old official and clear their barangay
      if (_existingOfficial != null) {
        await _fs.setOfficialActiveStatus(_existingOfficial!.uid, false);
        // Clear old official's occupancy from barangay doc
        await _fs.removeBarangayFromOfficial(
          officialUid: _existingOfficial!.uid,
          barangayId: barangayId,
          barangayName: barangayName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingOfficial != null
                  ? 'Official replaced successfully'
                  : 'Official account created successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      String msg = 'Failed to create account.';
      if (e.code == 'email-already-in-use') msg = 'Email already in use.';
      if (e.code == 'weak-password')
        msg = 'Password must be at least 6 characters.';
      if (mounted) _showError(msg);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showOverrideDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text(
              'Replace Official?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This barangay already has an assigned official:',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _existingOfficial!.name.isNotEmpty
                            ? _existingOfficial!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _existingOfficial!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          _existingOfficial!.email,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This official will be deactivated and replaced with the new one.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Official',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: _loadingMunicipalities
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Account Details'),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min 6 characters',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Barangay Assignment'),
                    const SizedBox(height: 12),
                    _DropdownField(
                      label: 'Municipality',
                      hint: 'Select municipality',
                      icon: Icons.location_city_outlined,
                      value: _selectedMunicipality,
                      items: _municipalities
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: _onMunicipalityChanged,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMunicipality != null) ...[
                      _loadingBarangays
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _BarangayDropdown(
                              barangays: _barangays,
                              selected: _selectedBarangay,
                              onChanged: _onBarangayChanged,
                            ),
                    ],
                    if (_loadingExisting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_loadingExisting &&
                        _selectedBarangay != null &&
                        _existingOfficial != null) ...[
                      const SizedBox(height: 16),
                      _ExistingOfficialCard(official: _existingOfficial!),
                    ],
                    if (!_loadingExisting &&
                        _selectedBarangay != null &&
                        _existingOfficial == null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No official assigned — ready to assign',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createOfficial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _existingOfficial != null
                                    ? 'Replace Official'
                                    : 'Create Official Account',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Text Field ────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
    );
  }
}

// ─── Dropdown Field ────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

// ─── Barangay Dropdown ─────────────────────────────────────────

class _BarangayDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> barangays;
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>?) onChanged;

  const _BarangayDropdown({
    required this.barangays,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (barangays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'No barangays found for this municipality.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: selected,
      hint: const Text(
        'Select barangay',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
      decoration: const InputDecoration(
        labelText: 'Barangay',
        prefixIcon: Icon(
          Icons.holiday_village_outlined,
          color: Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      items: barangays.map((b) {
        final hasOfficial =
            b['official_uid'] != null && b['official_uid'] != '';
        return DropdownMenuItem<Map<String, dynamic>>(
          value: b,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasOfficial
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b['barangay_name'] ?? '',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                hasOfficial ? 'Occupied' : 'Vacant',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: hasOfficial
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

// ─── Existing Official Card ────────────────────────────────────

class _ExistingOfficialCard extends StatelessWidget {
  final AppUser official;
  const _ExistingOfficialCard({required this.official});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Barangay Already Occupied',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    official.name.isNotEmpty
                        ? official.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      official.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      official.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: official.isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFF6B7280).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        official.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: official.isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Creating a new official will deactivate this account.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
