import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Sun, Moon, Github, Linkedin, Mail } from 'lucide-react';

// ---- SINGLE RESUME (GPU-FOCUSED) ------------------------------------------
const BASE =
  (typeof import.meta !== 'undefined' &&
    import.meta.env &&
    import.meta.env.BASE_URL) ||
  '/';

const RESUME_URL = `${BASE}Resume_Final.pdf`;

// ------------------------------------------
// Projects (GPU-first identity)
// ------------------------------------------
const projects = [
  {
    id: 'open-gpu-perf',
    title: 'OpenGPUPerf: CUDA Kernel Performance Workbench',
    category: 'GPU',
    stack: ['C++', 'CUDA', 'Python'],
    bullets: [
      'Hand-optimized GEMM and reduction kernels using shared-memory tiling, warp shuffle, and WMMA tensor cores.',
      'Built a reusable benchmarking harness with CUDA event timing for throughput tracking and roofline analysis.',
      'Profiling kernels using Nsight Compute (CLI) to analyze warp stalls, memory coalescing, and SM occupancy.',
      'Developing an auto-tuning engine to sweep tile sizes, block sizes, and unroll factors to maximize SM utilization.',
    ],
    link: '#',
  },
  {
    id: 'mi300x-mem',
    title: 'MI300X Memory-System Reverse Engineering & gem5 Calibration',
    category: 'ARCH',
    stack: ['CUDA', 'gem5', 'Python'],
    bullets: [
      'Designed CUDA microbenchmarks (pointer-chasing, stride sweeps) to measure L2/L3/HBM latency and bandwidth.',
      'Captured GPU performance counters to study chiplet-level cache behavior and bandwidth pressure.',
      'Calibrating gem5 MI300X memory subsystem (line size, associativity, latency stack) to reduce HW–sim mismatch.',
      'Established a reproducible methodology to reverse-engineer GPU memory systems using microbenchmarks.',
    ],
    link: '#',
  },
  {
    id: 'abft-gemm',
    title: 'ABFT-GEMM Reliability Study (ECE 753)',
    category: 'ARCH',
    stack: ['Python', 'Slurm'],
    bullets: [
      'Performed Monte-Carlo fault injection on GEMM to evaluate SDC rates and timing overhead.',
      'Automated large-scale HPC runs using Slurm to sweep matrix sizes and fault-injection rates.',
    ],
    link: '#',
  },
  {
    id: 'cuda-optimizer',
    title: 'ML-Guided CUDA Kernel Optimizer',
    category: 'GPU',
    stack: ['Python', 'PyTorch', 'CUDA'],
    bullets: [
      'Trained a PyTorch model to predict grid/block sizes, reducing manual tuning by >95%.',
      'Achieved up to ~30% runtime improvement on GEMM-like workloads using predicted configurations.',
      'Benchmarked using Slurm pipelines and CUDA event timers for reproducible performance comparisons.',
    ],
    link: 'https://github.com/Drogon4231/Ml-Guided-CUDA-Config',
  },
  {
    id: 'xgb-partitioning',
    title: 'ML-Assisted Task Graph Partitioning',
    category: 'GPU',
    stack: ['Python', 'XGBoost', 'pandas'],
    bullets: [
      'Predicted optimal TGD partition sizes with <5% error using graph-structural features.',
      'Reduced design-space exploration time by ~25% compared to exhaustive sweeps.',
    ],
    link: 'https://github.com/Drogon4231/ML-Partition-Predictor',
  },
];

const certifications = [
  {
    title: 'NVIDIA Deep Learning Institute (DLI)',
    subtitle: 'Getting Started with Accelerated Computing using CUDA C++',
    year: '2025',
    link: 'https://drogon4231.github.io/harshithkantamneni.github.io/public/My%20Learning%20%7C%20NVIDIA.pdf',
  },
];

const skillBuckets = [
  {
    title: '🚀 GPU / Performance',
    items: ['CUDA', 'Kernel Optimization', 'GPU Memory Hierarchy', 'Roofline Modeling'],
  },
  {
    title: '📊 HPC / Systems',
    items: ['Slurm', 'Linux', 'Benchmarking', 'Profiling'],
  },
  {
    title: '🏗️ Architecture / Modeling',
    items: ['gem5', 'McPAT', 'Computer Architecture'],
  },
  {
    title: '🧠 ML for Systems',
    items: ['PyTorch', 'XGBoost'],
  },
  {
    title: '💻 Programming',
    items: ['C', 'C++17', 'Python', 'Bash', 'Git'],
  },
];

// ------------------------------------------
const SectionTitle = ({ children }) => (
  <h2 className="text-3xl md:text-4xl font-extrabold mb-8 tracking-tight relative inline-block after:absolute after:left-0 after:-bottom-2 after:w-full after:h-1 after:bg-gradient-to-r after:from-emerald-400 after:to-cyan-500">
    {children}
  </h2>
);

export default function Portfolio() {
  const [dark, setDark] = useState(true);
  const [track, setTrack] = useState('GPU'); // Default: GPU focus

  useEffect(() => {
    const root = document.documentElement;
    dark ? root.classList.add('dark') : root.classList.remove('dark');
  }, [dark]);

  const filteredProjects = useMemo(() => {
    if (track === 'ALL') return projects;
    return projects.filter((p) => p.category === track);
  }, [track]);

  const scrollToProjects = () => {
    const el = document.getElementById('projects');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  const handleTrackSelect = (key) => {
    setTrack(key);
    scrollToProjects();
  };

  return (
    <div className="font-sans bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
      {/* NAV */}
      <header className="fixed top-0 inset-x-0 z-50 backdrop-blur-sm bg-white/70 dark:bg-gray-900/70 border-b border-gray-200 dark:border-gray-800">
        <nav className="max-w-6xl mx-auto flex items-center justify-between px-6 py-3">
          <a href="#hero" className="text-lg font-bold tracking-tight">
            HK
          </a>
          <ul className="hidden md:flex gap-6 text-sm font-medium">
            {['About', 'Projects', 'Certifications', 'Skills', 'Contact'].map((label) => (
              <li key={label}>
                <a href={`#${label.toLowerCase()}`} className="hover:text-emerald-500 transition-colors">
                  {label}
                </a>
              </li>
            ))}
          </ul>

          <button
            onClick={() => setDark(!dark)}
            aria-label="Toggle theme"
            className="p-2 rounded-full hover:bg-gray-200 dark:hover:bg-gray-800"
          >
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
        </nav>
      </header>

      <main className="pt-24 space-y-32">
        {/* HERO */}
        <section id="hero" className="min-h-[80vh] flex flex-col items-center text-center px-w">
          <motion.h1 className="text-6xl font-extrabold mb-6">Harshith Kantamneni</motion.h1>

          <p className="text-xl md:text-2xl max-w-3xl mb-10">
            Building modern computing systems through{' '}
            <span className="font-semibold">CUDA kernel optimization</span>,{' '}
            <span className="font-semibold">GPU memory hierarchy analysis</span>, and{' '}
            <span className="font-semibold">HPC benchmarking</span>.
          </p>

          {/* FILTERS */}
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            {[
              { key: 'GPU', label: 'CUDA / GPU Projects' },
              { key: 'ARCH', label: 'Architecture / Memory / Reliability' },
              { key: 'ALL', label: 'Show All Projects' },
            ].map((btn) => (
              <button
                key={btn.key}
                onClick={() => handleTrackSelect(btn.key)}
                className={`px-4 py-2 rounded-full text-sm border transition-colors ${
                  track === btn.key
                    ? 'bg-gradient-to-r from-emerald-500 to-cyan-500 text-white'
                    : 'border-emerald-500 text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-900/20'
                }`}
              >
                {btn.label}
              </button>
            ))}
          </div>

          {/* RESUME BUTTON */}
          <a
            href={RESUME_URL}
            className="px-6 py-3 rounded-full bg-gray-900 text-white dark:bg-white dark:text-gray-900 font-medium shadow hover:shadow-lg"
          >
            Download Resume
          </a>
        </section>

        {/* ABOUT */}
        <section id="about" className="max-w-4xl mx-auto px-6">
          <SectionTitle>About Me</SectionTitle>
          <p className="text-lg leading-relaxed">
            I focus on understanding how CUDA kernels interact with{' '}
            <strong>GPU memory systems</strong>, and how profiling, modeling,
            and machine learning can extract more useful work from hardware. I
            enjoy building performance workbenches, microbenchmarks, and
            auto-tuners to make architectural trade-offs measurable.
          </p>
        </section>

        {/* PROJECTS */}
        <section id="projects" className="max-w-6xl mx-auto px-6">
          <SectionTitle>
            Featured Projects ({filteredProjects.length})
          </SectionTitle>
          <div className="grid gap-8 md:grid-cols-2">
            {filteredProjects.map((p) => (
              <motion.a
                key={p.id}
                href={p.link}
                target={p.link?.startsWith('http') ? '_blank' : undefined}
                className="group block bg-white/60 dark:bg-gray-800/60 border rounded-2xl p-6 hover:-translate-y-1 hover:shadow-xl"
              >
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-xl font-bold group-hover:text-emerald-500">
                    {p.title}
                  </h3>
                  <span className="text-xs px-2 py-0.5 rounded-full border opacity-70">
                    {p.category}
                  </span>
                </div>

                <div className="flex flex-wrap gap-2 mb-3">
                  {p.stack.map((t) => (
                    <span
                      key={t}
                      className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-xs text-emerald-700 border border-emerald-500/20"
                    >
                      {t}
                    </span>
                  ))}
                </div>

                <ul className="list-disc pl-5 space-y-1.5 text-sm leading-relaxed">
                  {p.bullets.map((b, i) => (
                    <li key={i}>{b}</li>
                  ))}
                </ul>
              </motion.a>
            ))}
          </div>
        </section>

        {/* CERTIFICATIONS */}
        <section id="certifications" className="max-w-4xl mx-auto px-6">
          <SectionTitle>Certifications</SectionTitle>
          <div className="space-y-6">
            {certifications.map((c) => (
              <motion.div
                key={c.title}
                className="p-5 rounded-xl bg-white/60 dark:bg-gray-800/60 border"
              >
                <h3 className="text-lg font-bold">{c.title}</h3>
                <p className="text-sm opacity-80">
                  {c.subtitle} <span className="opacity-50">({c.year})</span>
                </p>
                {c.link && (
                  <a
                    href={c.link}
                    className="inline-block mt-2 text-emerald-500 hover:underline"
                    target="_blank"
                  >
                    View Certificate →
                  </a>
                )}
              </motion.div>
            ))}
          </div>
        </section>

        {/* SKILLS */}
        <section id="skills" className="max-w-5xl mx-auto px-6">
          <SectionTitle>Skills</SectionTitle>
          <div className="grid gap-8 md:grid-cols-2">
            {skillBuckets.map((bucket) => (
              <div key={bucket.title}>
                <h3 className="mb-2 font-semibold">{bucket.title}</h3>
                <ul className="flex flex-wrap gap-2">
                  {bucket.items.map((item) => (
                    <li
                      key={item}
                      className="px-3 py-1 rounded-full bg-emerald-500/10 text-sm border border-emerald-500/20"
                    >
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        {/* CONTACT */}
        <section id="contact" className="max-w-md text-center mx-auto px-6">
          <SectionTitle>Let’s Connect</SectionTitle>
          <p className="mb-6 text-lg">
            Feel free to reach out if you'd like to discuss CUDA kernels,
            performance engineering, or GPU architecture.
          </p>
          <a
            href="mailto:kantamneniharshith@gmail.com"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-gradient-to-r from-fuchsia-500 to-pink-500 text-white font-medium shadow-lg hover:shadow-xl"
          >
            <Mail size={18} /> Say Hello
          </a>
          <div className="flex justify-center gap-6 mt-8">
            <a href="https://github.com/Drogon4231" className="hover:text-emerald-500">
              <Github size={22} />
            </a>
            <a href="https://linkedin.com/in/hk4231" className="hover:text-emerald-500">
              <Linkedin size={22} />
            </a>
          </div>
        </section>
      </main>

      <footer className="py-8 text-center text-sm opacity-70">
        © {new Date().getFullYear()} Harshith Kantamneni — GPU Performance Portfolio
      </footer>
    </div>
  );
}
