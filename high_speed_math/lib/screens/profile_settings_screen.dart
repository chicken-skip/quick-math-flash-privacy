import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccess = false;
  bool _showUserIdCopied = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    await _profileService.initializeProfile();

    if (mounted) {
      setState(() {
        _nameController.text = _profileService.currentProfile?.displayName ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyUserId() async {
    final userId = _authService.userId;
    if (userId != null) {
      await Clipboard.setData(ClipboardData(text: userId));
      setState(() {
        _showUserIdCopied = true;
      });
      // Hide copied message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showUserIdCopied = false;
          });
        }
      });
    }
  }

  Future<void> _saveName() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccess = false;
    });

    final newName = _nameController.text.trim();
    final appLocalizations = AppLocalizations.of(context)!;

    // Validate
    final validation = _profileService.validateDisplayName(newName);
    if (!validation.isValid) {
      String errorMessage;
      switch (validation.errorType) {
        case 'empty':
          errorMessage = appLocalizations.nameErrorEmpty;
          break;
        case 'too_short':
          errorMessage = appLocalizations.nameErrorTooShort;
          break;
        case 'too_long':
          errorMessage = appLocalizations.nameErrorTooLong;
          break;
        case 'invalid_chars':
          errorMessage = appLocalizations.nameErrorInvalidChars;
          break;
        case 'banned_word':
          errorMessage = appLocalizations.nameErrorBannedWord;
          break;
        default:
          errorMessage = appLocalizations.nameUpdateFailed;
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
      return;
    }

    // Check cooldown
    if (!_profileService.canChangeName()) {
      final remainingHours = _profileService.getRemainingCooldownHours();
      setState(() {
        _errorMessage = appLocalizations.nameChangeCooldown(remainingHours);
        _isLoading = false;
      });
      return;
    }

    // Update
    final result = await _profileService.updateDisplayName(newName);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isValid) {
          _showSuccess = true;
          _nameFocus.unfocus();
          // Hide success message after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showSuccess = false;
              });
            }
          });
        } else {
          _errorMessage = appLocalizations.nameUpdateFailed;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canChange = _profileService.canChangeName();
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(appLocalizations.profileSettings),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Display name section
                  Text(
                    appLocalizations.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.displayNameDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name input field
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    maxLength: UserProfileService.maxNameLength,
                    decoration: InputDecoration(
                      hintText: appLocalizations.enterYourName,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E293B),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      counterText: '${_nameController.text.length}/${UserProfileService.maxNameLength}',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // Guidelines
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appLocalizations.nameRules,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGuideline(appLocalizations.nameRule1),
                        _buildGuideline(appLocalizations.nameRule2),
                        _buildGuideline(appLocalizations.nameRule3),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // User ID section
                  Text(
                    appLocalizations.userId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.userIdDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User ID display with copy button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _authService.userId ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _copyUserId,
                          icon: const Icon(Icons.copy, size: 20),
                          color: const Color(0xFF1E293B),
                          tooltip: appLocalizations.copyUserId,
                        ),
                      ],
                    ),
                  ),

                  // User ID copied message
                  if (_showUserIdCopied)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            appLocalizations.userIdCopied,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // User ID note
                  Text(
                    appLocalizations.userIdNote,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success message
                  if (_showSuccess)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              appLocalizations.nameUpdateSuccess,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null || _showSuccess)
                    const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canChange && !_isLoading ? _saveName : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              appLocalizations.save,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Cooldown warning
                  if (!canChange)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        appLocalizations.nameChangeAvailableIn(_profileService.getRemainingCooldownHours()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
