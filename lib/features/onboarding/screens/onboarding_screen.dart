import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: IntroductionScreen(
            globalBackgroundColor: Colors.transparent,
            pages: _pages(context),
            showSkipButton: true,
            skip: _ActionLabel(text: tr('onboarding_skip')),
            next: _ActionLabel(text: tr('onboarding_next'), isPrimary: true),
            done: _ActionLabel(text: tr('onboarding_start'), isPrimary: true),
            onDone: onFinished,
            onSkip: () => onFinished(),
            dotsDecorator: DotsDecorator(
              size: const Size(10, 10),
              activeSize: const Size(26, 10),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              activeColor: colorScheme.primary,
              color: colorScheme.primary.withValues(alpha: 0.22),
              spacing: const EdgeInsets.symmetric(horizontal: 4),
            ),
            controlsMargin: const EdgeInsets.only(bottom: 6),
            controlsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  List<PageViewModel> _pages(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
    );

    final data = <_OnboardingData>[
      const _OnboardingData(
        imagePath: 'assets/onboarding/onboarding1.svg',
        titleKey: 'onboarding_page_1_title',
        bodyKey: 'onboarding_page_1_body',
      ),
      const _OnboardingData(
        imagePath: 'assets/onboarding/onboarding2.svg',
        titleKey: 'onboarding_page_2_title',
        bodyKey: 'onboarding_page_2_body',
      ),
      const _OnboardingData(
        imagePath: 'assets/onboarding/onboarding3.svg',
        titleKey: 'onboarding_page_3_title',
        bodyKey: 'onboarding_page_3_body',
      ),
      const _OnboardingData(
        imagePath: 'assets/onboarding/onboarding4.svg',
        titleKey: 'onboarding_page_4_title',
        bodyKey: 'onboarding_page_4_body',
      ),
      const _OnboardingData(
        imagePath: 'assets/onboarding/onboarding5.svg',
        titleKey: 'onboarding_page_5_title',
        bodyKey: 'onboarding_page_5_body',
      ),
    ];

    return data
        .map(
          (item) => PageViewModel(
            titleWidget: Text(
              tr(item.titleKey),
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            bodyWidget: Text(
              tr(item.bodyKey),
              textAlign: TextAlign.center,
              style: bodyStyle,
            ),
            image: _HeroImage(imagePath: item.imagePath),
            decoration: const PageDecoration(
              pageColor: Colors.transparent,
              imagePadding: EdgeInsets.zero,
              imageFlex: 10,
              bodyFlex: 3,
              titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              bodyPadding: EdgeInsets.fromLTRB(24, 3, 24, 10),
            ),
          ),
        )
        .toList();
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 36, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                'assets/images/logo_projexy.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                tr('onboarding_app_name'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: colorScheme.onSurface,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SvgPicture.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.text, this.isPrimary = false});

  final String text;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isPrimary) {
      return Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 129),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.imagePath,
    required this.titleKey,
    required this.bodyKey,
  });

  final String imagePath;
  final String titleKey;
  final String bodyKey;
}
