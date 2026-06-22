"""Generate lib/ui/guide_content.dart (the Sustain 101 book) from the compiled
JSON the guide-compile workflow produced. Run: python tools/gen_guide.py"""
import json, io, os

SRC = r"C:\Users\morni\AppData\Local\Temp\claude\d--Dev-Trilumos-hourglass\e966c05c-7df9-4f7d-b8b4-54fd409bd1c4\tasks\w6xpaw0p8.output"
OUT = os.path.join(os.path.dirname(__file__), "..", "lib", "ui", "guide_content.dart")


def esc(s):
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")


def main():
    data = json.load(io.open(SRC, encoding="utf-8"))["result"]["chapters"]
    L = [
        "// Sustain 101 -- the in-app guide content. GENERATED from the guide-compile",
        "// workflow (regenerate via tools/gen_guide.py, do not hand-edit). The single",
        "// source of truth for every mechanism, rule, and feature, written for users.",
        "",
        "class GuideTopic {",
        "  final String heading;",
        "  final String body;",
        "  final List<String> bullets;",
        "  const GuideTopic(this.heading, this.body, [this.bullets = const []]);",
        "}",
        "",
        "class GuideChapter {",
        "  final String title;",
        "  final String summary;",
        "  final List<GuideTopic> topics;",
        "  const GuideChapter(this.title, this.summary, this.topics);",
        "}",
        "",
        "const kSustain101 = <GuideChapter>[",
    ]
    for ch in data:
        L.append("  GuideChapter('%s', '%s', [" % (esc(ch["title"]), esc(ch["summary"])))
        for t in ch["topics"]:
            L.append("    GuideTopic(")
            L.append("      '%s'," % esc(t["heading"]))
            L.append("      '%s'," % esc(t["body"]))
            bullets = t.get("bullets", [])
            if bullets:
                inner = ", ".join("'%s'" % esc(b) for b in bullets)
                L.append("      [%s]," % inner)
            L.append("    ),")
        L.append("  ]),")
    L.append("];")
    io.open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")
    print("wrote", os.path.normpath(OUT), "--", len(data), "chapters,",
          sum(len(c["topics"]) for c in data), "topics")


if __name__ == "__main__":
    main()
