import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'guide_content.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/surface_tile.dart';

/// "Sustain 101" — the book of the app. A table of contents of chapters; each
/// chapter opens to its topics. Content lives in [kSustain101] (generated from
/// the guide-compile workflow, the single source of truth for every mechanism).
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Sustain 101'),
                const SizedBox(height: HgSpacing.lg),
                Text(
                  'The book of the app.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.4,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: HgSpacing.sm),
                Text(
                  'Every method, rule, and number behind your focus — '
                  'one chapter at a time.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 15,
                    height: 1.6,
                    color: hg.textSecondary,
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),
                _Eyebrow('CONTENTS'),
                const SizedBox(height: HgSpacing.md),
                for (var i = 0; i < kSustain101.length; i++) ...[
                  _ChapterCard(index: i, chapter: kSustain101[i]),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: HgSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single chapter page: its topics, then a "next chapter" link so the guide
/// reads like a book. [GuideChapterScreen]s replace one another so the back
/// arrow always returns to the table of contents.
class GuideChapterScreen extends StatelessWidget {
  final int index;
  const GuideChapterScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final chapter = kSustain101[index];
    final hasNext = index < kSustain101.length - 1;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Sustain 101'),
                const SizedBox(height: HgSpacing.lg),
                _Eyebrow('CHAPTER ${(index + 1).toString().padLeft(2, '0')}'),
                const SizedBox(height: HgSpacing.sm),
                Text(
                  chapter.title,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: HgSpacing.sm),
                Text(
                  chapter.summary,
                  style: TextStyle(
                    fontFamily: HgFont.serif,
                    fontSize: 16,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: hg.textSecondary,
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),
                for (final t in chapter.topics) _TopicBlock(topic: t),
                if (hasNext) ...[
                  const SizedBox(height: HgSpacing.sm),
                  SurfaceTile(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GuideChapterScreen(index: index + 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Eyebrow('NEXT'),
                              const SizedBox(height: 4),
                              Text(
                                kSustain101[index + 1].title,
                                style: TextStyle(
                                  fontFamily: HgFont.sans,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: hg.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded,
                            color: hg.accent, size: 20),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: HgSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Back to contents',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 14,
                        color: hg.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One topic: a prominent heading, its paragraphs, and any takeaway bullets.
class _TopicBlock extends StatelessWidget {
  final GuideTopic topic;
  const _TopicBlock({required this.topic});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final paragraphs = topic.body.split('\n\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic.heading,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: -0.2,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: HgSpacing.sm),
            Text(
              paragraphs[i],
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                height: 1.6,
                color: hg.textSecondary,
              ),
            ),
          ],
          if (topic.bullets.isNotEmpty) ...[
            const SizedBox(height: HgSpacing.md),
            for (final b in topic.bullets) _Bullet(b),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: HgSpacing.sm),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hg.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14.5,
                height: 1.5,
                color: hg.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small uppercase eyebrow label (CONTENTS / CHAPTER 03 / NEXT).
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: hg.textMuted,
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final int index;
  final GuideChapter chapter;
  const _ChapterCard({required this.index, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GuideChapterScreen(index: index)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: hg.accent,
              ),
            ),
          ),
          const SizedBox(width: HgSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chapter.title,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter.summary,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 13.5,
                    height: 1.45,
                    color: hg.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: HgSpacing.xs),
            child: Icon(Icons.chevron_right_rounded,
                color: hg.textMuted, size: 22),
          ),
        ],
      ),
    );
  }
}
