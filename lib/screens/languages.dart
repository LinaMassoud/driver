import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguagePage extends ConsumerStatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguagePage> {
  String? tempSelectedLanguage; // 🔹 temporary selection

  final List<Map<String, String>> languages = const [
    {'name': 'English', 'icon': 'assets/icons/english.png', 'local': 'en'},
    {'name': 'العربية', 'icon': 'assets/icons/arabic.png', 'local': 'ar'},
    {'name': 'اردو', 'icon': 'assets/icons/ardo.png', 'local': 'ur'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with currently saved language
    tempSelectedLanguage = ref.read(languageProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF05ABD7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    loc.languageTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Language list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 0),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = tempSelectedLanguage == lang['local'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          tempSelectedLanguage = lang['local'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF80D9F2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF05ABD7)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(lang['icon']!, width: 30, height: 30),
                            const SizedBox(width: 12),
                            Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom container with save button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05ABD7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    if (tempSelectedLanguage != null) {
                      languageNotifier.selectLanguage(tempSelectedLanguage!);
                      languageNotifier.saveLanguage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.languageSaved)),
                      );
                    }
                  },
                  child: Text(
                    loc.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
