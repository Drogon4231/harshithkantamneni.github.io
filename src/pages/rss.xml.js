import rss from '@astrojs/rss';

export async function GET(context) {
  return rss({
    title: 'Harshith Kantamneni',
    description: 'I design and run autonomous AI labs. Reports, notes, and operating decisions.',
    site: context.site,
    items: [
      {
        title: 'Recursive Verification-Surface Collapse in Self-Graded Autonomous Engineering Systems',
        pubDate: new Date('2026-05-15'),
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
    ],
    customData: '<language>en-us</language>',
  });
}
