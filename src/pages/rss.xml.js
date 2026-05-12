import rss from '@astrojs/rss';

export async function GET(context) {
  return rss({
    title: 'Harshith Kantamneni',
    description: 'I design and run autonomous AI labs. Reports, notes, and operating decisions.',
    site: context.site,
    stylesheet: '/harshithkantamneni.github.io/rss.xsl',
    items: [
      {
        title: 'Recursive Verification-Surface Collapse in Self-Graded Autonomous Engineering Systems',
        pubDate: new Date('2026-05-12'),
        description: 'Three times in 100 cycles, my autonomous lab passed its own tests while quietly breaking. Notes on the null-set principal problem and three structural principles for disrupting it.',
        link: '/reports/recursive-verification-surface-collapse',
      },
      {
        title: 'Twelve cycles of byte-identical builds',
        pubDate: new Date('2026-05-05'),
        description: 'What it takes for an autonomous lab to produce reproducible binaries across cycles, and why it matters for verification.',
        link: '/notes/byte-identical-builds',
      },
      {
        title: 'Tier dispatchers per task, not per role',
        pubDate: new Date('2026-05-03'),
        description: 'Why role-level model tiering misses the point, and what task-level tiering buys you instead.',
        link: '/notes/tier-per-task',
      },
      {
        title: 'Same-family LLM judge bias is real',
        pubDate: new Date('2026-05-02'),
        description: 'ICLR 2026 paper on preference leakage in LLM-as-judge, applied to a quartet of Claude opus instances reviewing each other.',
        link: '/notes/llm-judge-bias',
      },
      {
        title: 'Six cycles after the verification-depth directive',
        pubDate: new Date('2026-04-28'),
        description: 'Running notes from the first six cycles of a self-graded autonomous lab responding to a directive that named the failure mode it had been quietly running on.',
        link: '/notes/six-cycles-after-the-directive',
      },
      {
        title: 'Cross-Lab Diagnosis: Why an Autonomous Research Lab Stopped Adapting',
        pubDate: new Date('2026-04-16'),
        description: 'Notes from observing one autonomous AI lab from inside another. Four reinforcing patterns that made a Director stop redesigning its own organization, and the five structural fixes that gave it permission to adapt again.',
        link: '/reports/cross-lab-diagnosis',
      },
    ],
    customData: '<language>en-us</language>',
  });
}
