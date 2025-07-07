import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/home.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatefulWidget {
  final Barcode result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF1E1E2E), Color(0xFF2A2A3A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildResultCard(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text(
              'Scan Result',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultHeader(),
            const SizedBox(height: 24),
            _buildResultContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconForType(), color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMainTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getTypeName(widget.result.format),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent() {
    final String? code = widget.result.code;
    if (code == null) {
      return _buildErrorContent();
    }

    // Check for URL first
    final Uri? uri = Uri.tryParse(code);
    final bool isUrl = uri != null && uri.hasScheme;

    if (isUrl) {
      return _buildUrlResult(uri);
    }

    // Check for other types
    if (code.toLowerCase().startsWith('begin:vcard')) {
      return _buildVCardResult(code);
    } else if (code.toLowerCase().startsWith('mailto:')) {
      return _buildEmailResult(code);
    } else if (code.toLowerCase().startsWith('smsto:')) {
      return _buildSmsResult(code);
    } else if (code.toLowerCase().startsWith('wifi:')) {
      return _buildWifiResult(code);
    } else if (code.toLowerCase().startsWith('bitcoin:')) {
      return _buildBitcoinResult(code);
    } else if (code.toLowerCase().contains('twitter.com') ||
        code.toLowerCase().startsWith('twitter:')) {
      return _buildTwitterResult(code);
    } else if (code.toLowerCase().contains('facebook.com') ||
        code.toLowerCase().startsWith('fb:')) {
      return _buildFacebookResult(code);
    } else if (code.toLowerCase().endsWith('.pdf')) {
      return _buildPdfResult(code);
    } else if (code.toLowerCase().endsWith('.mp3')) {
      return _buildMp3Result(code);
    } else if (code.toLowerCase().contains('play.google.com') ||
        code.toLowerCase().contains('apps.apple.com')) {
      return _buildAppStoreResult(code);
    } else if (code.toLowerCase().endsWith('.jpg') ||
        code.toLowerCase().endsWith('.jpeg') ||
        code.toLowerCase().endsWith('.png') ||
        code.toLowerCase().endsWith('.gif')) {
      return _buildImageResult(code);
    } else {
      return _buildTextResult(code);
    }
  }

  Widget _buildErrorContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24),
          SizedBox(width: 12),
          Text(
            'No data found in QR code',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    List<Widget>? details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (details != null) ...[const SizedBox(height: 12), ...details],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final String? code = widget.result.code;
    if (code == null) return const SizedBox.shrink();

    List<Widget> buttons = [];

    // Always add copy button
    buttons.add(
      _buildActionButton(
        icon: Icons.copy,
        label: 'Copy',
        onTap: () => _copyToClipboard(code),
        isPrimary: false,
      ),
    );

    // Add specific action buttons based on content type
    final Uri? uri = Uri.tryParse(code);
    if (uri != null && uri.hasScheme) {
      buttons.insert(
        0,
        _buildActionButton(
          icon: Icons.open_in_new,
          label: 'Open',
          onTap: () => _launchUrl(uri),
          isPrimary: true,
        ),
      );
    } else if (code.toLowerCase().startsWith('mailto:')) {
      buttons.insert(
        0,
        _buildActionButton(
          icon: Icons.email,
          label: 'Send Email',
          onTap: () => _launchUrl(Uri.parse(code)),
          isPrimary: true,
        ),
      );
    } else if (code.toLowerCase().startsWith('smsto:')) {
      buttons.insert(
        0,
        _buildActionButton(
          icon: Icons.message,
          label: 'Send SMS',
          onTap: () =>
              _launchUrl(Uri.parse(code.replaceFirst('smsto:', 'sms:'))),
          isPrimary: true,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: buttons.map((button) => Expanded(child: button)).toList(),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.qr_code_scanner,
          label: 'Scan Another',
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const QRViewExample()),
            );
          },

          isPrimary: false,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool fullWidth = false,
  }) {
    return Container(
      margin: fullWidth
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  // Content type builders
  Widget _buildUrlResult(Uri uri) {
    return _buildContentCard(
      title: 'Website URL',
      subtitle: uri.toString(),
      icon: Icons.link,
    );
  }

  Widget _buildVCardResult(String vcard) {
    final lines = vcard.split('\n');
    String name = '';
    String phone = '';
    String email = '';

    for (var line in lines) {
      if (line.toLowerCase().startsWith('fn:')) {
        name = line.substring(3);
      } else if (line.toLowerCase().startsWith('tel:')) {
        phone = line.substring(4);
      } else if (line.toLowerCase().startsWith('email:')) {
        email = line.substring(6);
      }
    }

    return _buildContentCard(
      title: 'Contact Information',
      subtitle: name.isNotEmpty ? name : 'Contact',
      icon: Icons.contact_page,
      details: [
        if (phone.isNotEmpty) _buildDetailRow('Phone', phone),
        if (email.isNotEmpty) _buildDetailRow('Email', email),
      ],
    );
  }

  Widget _buildEmailResult(String email) {
    final address = email.substring(7);
    return _buildContentCard(
      title: 'Email Address',
      subtitle: address,
      icon: Icons.email,
    );
  }

  Widget _buildSmsResult(String sms) {
    final parts = sms.substring(6).split(':');
    final number = parts[0];
    final message = parts.length > 1 ? parts[1] : '';

    return _buildContentCard(
      title: 'SMS Message',
      subtitle: number,
      icon: Icons.sms,
      details: message.isNotEmpty
          ? [_buildDetailRow('Message', message)]
          : null,
    );
  }

  Widget _buildWifiResult(String wifi) {
    final params = wifi.substring(5).split(';');
    String ssid = '';
    String password = '';
    String security = '';

    for (var param in params) {
      if (param.toLowerCase().startsWith('s:')) {
        ssid = param.substring(2);
      } else if (param.toLowerCase().startsWith('p:')) {
        password = param.substring(2);
      } else if (param.toLowerCase().startsWith('t:')) {
        security = param.substring(2);
      }
    }

    return _buildContentCard(
      title: 'WiFi Network',
      subtitle: ssid,
      icon: Icons.wifi,
      details: [
        if (security.isNotEmpty) _buildDetailRow('Security', security),
        if (password.isNotEmpty) _buildDetailRow('Password', password),
      ],
    );
  }

  Widget _buildBitcoinResult(String bitcoin) {
    final address = bitcoin.substring(8);
    return _buildContentCard(
      title: 'Bitcoin Address',
      subtitle: address,
      icon: Icons.currency_bitcoin,
    );
  }

  Widget _buildTwitterResult(String twitter) {
    return _buildContentCard(
      title: 'Twitter Profile',
      subtitle: twitter,
      icon: Icons.alternate_email,
    );
  }

  Widget _buildFacebookResult(String facebook) {
    return _buildContentCard(
      title: 'Facebook Page',
      subtitle: facebook,
      icon: Icons.facebook,
    );
  }

  Widget _buildPdfResult(String pdf) {
    return _buildContentCard(
      title: 'PDF Document',
      subtitle: pdf,
      icon: Icons.picture_as_pdf,
    );
  }

  Widget _buildMp3Result(String mp3) {
    return _buildContentCard(
      title: 'MP3 Audio File',
      subtitle: mp3,
      icon: Icons.music_note,
    );
  }

  Widget _buildAppStoreResult(String appStore) {
    return _buildContentCard(
      title: 'App Store Link',
      subtitle: appStore,
      icon: Icons.store,
    );
  }

  Widget _buildImageResult(String image) {
    return _buildContentCard(
      title: 'Image File',
      subtitle: image,
      icon: Icons.image,
    );
  }

  Widget _buildTextResult(String text) {
    return _buildContentCard(
      title: 'Text Content',
      subtitle: text,
      icon: Icons.text_snippet,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType() {
    final String? code = widget.result.code;
    if (code == null) return Icons.error;

    if (code.toLowerCase().startsWith('begin:vcard')) return Icons.contact_page;
    if (code.toLowerCase().startsWith('mailto:')) return Icons.email;
    if (code.toLowerCase().startsWith('smsto:')) return Icons.sms;
    if (code.toLowerCase().startsWith('wifi:')) return Icons.wifi;
    if (code.toLowerCase().startsWith('bitcoin:')) {
      return Icons.currency_bitcoin;
    }
    if (code.toLowerCase().contains('twitter.com') ||
        code.toLowerCase().startsWith('twitter:')) {
      return Icons.alternate_email;
    }
    if (code.toLowerCase().contains('facebook.com') ||
        code.toLowerCase().startsWith('fb:')) {
      return Icons.facebook;
    }
    if (code.toLowerCase().endsWith('.pdf')) return Icons.picture_as_pdf;
    if (code.toLowerCase().endsWith('.mp3')) return Icons.music_note;
    if (code.toLowerCase().contains('play.google.com') ||
        code.toLowerCase().contains('apps.apple.com')) {
      return Icons.store;
    }
    if (code.toLowerCase().endsWith('.jpg') ||
        code.toLowerCase().endsWith('.jpeg') ||
        code.toLowerCase().endsWith('.png') ||
        code.toLowerCase().endsWith('.gif')) {
      return Icons.image;
    }

    final Uri? uri = Uri.tryParse(code);
    if (uri != null && uri.hasScheme) return Icons.link;

    return Icons.text_snippet;
  }

  String _getTypeName(BarcodeFormat format) {
    return format.toString().split('.').last;
  }

  String _getMainTitle() {
    final String? code = widget.result.code;
    if (code == null) return 'No data';

    if (code.toLowerCase().startsWith('begin:vcard')) return 'Contact';
    if (code.toLowerCase().startsWith('mailto:')) return 'Email';
    if (code.toLowerCase().startsWith('smsto:')) return 'SMS';
    if (code.toLowerCase().startsWith('wifi:')) return 'WiFi Network';
    if (code.toLowerCase().startsWith('bitcoin:')) return 'Bitcoin Address';
    if (code.toLowerCase().contains('twitter.com') ||
        code.toLowerCase().startsWith('twitter:')) {
      return 'Twitter';
    }
    if (code.toLowerCase().contains('facebook.com') ||
        code.toLowerCase().startsWith('fb:')) {
      return 'Facebook';
    }
    if (code.toLowerCase().endsWith('.pdf')) return 'PDF Document';
    if (code.toLowerCase().endsWith('.mp3')) return 'MP3 Audio';
    if (code.toLowerCase().contains('play.google.com') ||
        code.toLowerCase().contains('apps.apple.com')) {
      return 'App Store';
    }
    if (code.toLowerCase().endsWith('.jpg') ||
        code.toLowerCase().endsWith('.jpeg') ||
        code.toLowerCase().endsWith('.png') ||
        code.toLowerCase().endsWith('.gif')) {
      return 'Image';
    }

    final Uri? uri = Uri.tryParse(code);
    if (uri != null && uri.hasScheme) return 'Web Link';

    return 'Text Content';
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open ${url.toString()}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening link', isError: true);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showSnackBar('Copied to clipboard');
    } catch (e) {
      _showSnackBar('Failed to copy', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
