import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Sun, Moon, Github, Linkedin, Mail } from 'lucide-react';

// ---- RESUME URLS (GitHub Pages-safe) ---------------------------------------
// Place both PDFs in your /public folder as GPU_Resume.pdf and RTL_Resume.pdf.
// For Vite:
const BASE = (import.meta?.env?.BASE_URL as string) || '/';
// For CRA, use this instead:
// const BASE = process.env.PUBLIC_URL || '/';

const GPU_RESUME_URL = `${BASE}GPU_Resume.pdf`;
const RTL_RESUME_URL = `${BASE}RTL_Resume.pdf`;

// ------------------------------------------
// 1 ▸ Data (projects + skills + certs)
// ------------------------------------------
const projects = [
  // GPU / Performance
  {
    id: 'cuda-optimizer',
    title: 'ML-Guided CUDA Kernel Optimizer',
    category: 'GPU',
    stack: ['Python', 'PyTorch', 'CUDA'],
    bullets: [
      'PyTorch MLP predicts grid/block sizes on-the-fly to improve kernel throughput (~30% speedup vs. static configs).',
      'One inference replaces exhaustive grid-search, cutting tuning time by >95% for GEMM-like workloads.',
      'Benchmarked with CUDA event timers and workload-scaling tests; validated prediction stability across problem sizes.',
    ],
    link: 'https://github.com/Drogon4231/Ml-Guided-CUDA-Config',
  },
  {
    id: 'xgb-partitioning',
    title: 'ML-Assisted Task Graph Partitioning',
    category: 'GPU',
    stack: ['Python', 'XGBoost', 'pandas'],
    bullets: [
      '< 5% MAE XGBoost regressor predicts runtime-optimal partition sizes for 2,000+ task graphs.',
      'Speeds simulation/design-space exploration by ~25% vs. exhaustive sweeps; enables reliable nightly CI.',
      'Packaged as Python API + CLI; reproducible runs with fixed seeds and version-pinned dependencies.',
    ],
    link: 'https://github.com/Drogon4231/ML-Partition-Predictor',
  },

  // RTL / Architecture
  {
    id: 'gem5-arch-modeling',
    title: 'Architectural Performance Modeling using gem5',
    category: 'RTL', // keep RTL so the RTL filter shows this card
    stack: ['gem5', 'Python', 'McPAT'],
    bullets: [
      'Profiled TimingSimple, Minor, and O3 CPU models; analyzed CPI and energy trade-offs.',
      'Benchmarked IAXPY, SAXPY, and DAXPY workloads; studied instruction mix and cache/memory behavior.',
      'Automated runs + metric extraction; correlated gem5/McPAT outputs with RTL design trade-offs.',
    ],
    link: '#',
  },
  {
    id: 'wisc-f24',
    title: '5-Stage Pipelined RISC CPU (WISC-F24)',
    category: 'RTL',
    stack: ['Verilog', 'ModelSim', 'WISC-F24'],
    bullets: [
      'Hazard-free pipeline with full forwarding and branch handling.',
      'Cycle-accurate ModelSim testbench achieves 100% instruction coverage; modular verification benches.',
      'Waveform-driven debug for stall/flush corner cases; parameterized modules for clean synthesis.',
    ],
    link: '#',
  },
  {
    id: 'knights-tour',
    title: 'FSM-Based Knight’s Tour Solver (FPGA Accelerator)',
    category: 'RTL',
    stack: ['SystemVerilog', 'Intel Quartus', 'UART/SPI'],
    bullets: [
      'Pipelined state machine meets 333 MHz timing closure on FPGA (Quartus Prime).',
      'Host control via custom UART/SPI bridge; live step/undo commands.',
      'Post-synthesis gate-level checks confirm timing + functional correctness.',
    ],
    link: '#',
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
    title: '⚙️ Hardware / RTL',
    items: ['Verilog', 'SystemVerilog', 'RTL Design & Verification', 'Static Timing Analysis'],
  },
  {
    title: '🔧 EDA / FPGA Tools',
    items: ['ModelSim', 'Intel Quartus', 'Altium Designer'],
  },
  {
    title: '🏗️ Sim / Arch Tools',
    items: ['gem5'],
  },
  {
    title: '📈 Acceleration / GPUs',
    items: ['CUDA', 'TensorRT'],
  },
  {
    title: '🧠 ML Frameworks',
    items: ['PyTorch', 'XGBoost', 'scikit-learn'],
  },
  {
    title: '💻 Languages / Systems',
    items: ['C', 'C++17', 'Python', 'Bash', 'Git'],
  },
  {
    title: '📡 Embedded / Interfaces',
    items: ['PSoC 6', 'FreeRTOS', 'I²C / SPI / UART / CAN'],
  },
];

// ------------------------------------------
const SectionTitle = ({ children }: { children: React.ReactNode }) => (
  <h2 className="text-3xl md:text-4xl font-extrabold mb-8 tracking-tight relative inline-block after:content-[''] after:absolute after:left-0 after:-bottom-2 after:w-full after:h-1 after:bg-gradient-to-r after:from-emerald-400 after:to-cyan-500 dark:after:from-emerald-500/60 dark:after:to-cyan-500/60">
    {children}
  </h2>
);

export default function Portfolio() {
  const [dark, setDark] = useState(true);
  const [track, setTrack] = useState<'ALL' | 'GPU' | 'RTL'>('ALL');
  const [primaryResume, setPrimaryResume] = useState<'GPU' | 'RTL'>('GPU');

  useEffect(() => {
    const root = document.documentElement;
    dark ? root.classList.add('dark') : root.classList.remove('dark');
  }, [dark]);

  const filteredProjects = useMemo(() => {
    if (track === 'ALL') return projects;
    return projects.filter((p) => p.category === track);
  }, [track]);

  // Smoothly scroll to the projects grid when a track is chosen
  const scrollToProjects = () => {
    const el = document.getElementById('projects');
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const handleTrackSelect = (key: 'ALL' | 'GPU' | 'RTL') => {
    setTrack(key);
    if (key === 'GPU') setPrimaryResume('GPU');
    if (key === 'RTL') setPrimaryResume('RTL');
    scrollToProjects();
  };

  return (
    <div className="font-sans bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 transition-colors duration-300">
      {/* NAV */}
      <header className="fixed top-0 inset-x-0 z-50 backdrop-blur-sm bg-white/70 dark:bg-gray-900/70 border-b border-gray-200 dark:border-gray-800">
        <nav className="max-w-6xl mx-auto flex items-center justify-between px-6 py-3">
          <a href="#hero" className="text-lg font-bold tracking-tight">HK</a>
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
            className="p-2 rounded-full hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors"
          >
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
        </nav>
      </header>

      <main className="pt-24 space-y-32 overflow-x-hidden">
        {/* HERO */}
        <section id="hero" className="relative min-h-[80vh] flex flex-col items-center justify-center text-center px-6">
          <motion.div
            className="absolute top-0 left-1/2 w-[120%] h-[120%] -translate-x-1/2 -z-10 bg-gradient-to-tr from-emerald-400/40 via-cyan-500/30 to-fuchsia-500/20 blur-3xl rotate-12"
            initial={{ scale: 1.2, y: -80 }}
            animate={{ scale: 1.0, y: 0 }}
            transition={{ duration: 2, ease: 'easeOut' }}
          />
          <motion.h1
            className="text-5xl sm:text-6xl md:text-7xl font-extrabold tracking-tight mb-6 leading-tight"
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            Harshith Kantamneni
          </motion.h1>

          {/* Hero subtitle (balanced) */}
          <motion.p
            className="text-xl md:text-2xl max-w-3xl mb-10 leading-relaxed"
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.8 }}
          >
            Building at the intersection of <span className="font-semibold">architecture</span>,{' '}
            <span className="font-semibold">performance</span>, and <span className="font-semibold">learning</span> — 
            where data and design come together to shape modern computing systems.
          </motion.p>

          {/* Track Selector */}
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            {[
              { key: 'ALL' as const, label: 'All Projects' },
              { key: 'RTL' as const, label: 'Explore RTL / Architecture' },
              { key: 'GPU' as const, label: 'Explore GPU / Performance' },
            ].map((btn) => (
              <button
                key={btn.key}
                onClick={() => handleTrackSelect(btn.key)}
                className={`px-4 py-2 rounded-full border text-sm font-medium transition-colors ${
                  track === btn.key
                    ? 'bg-gradient-to-r from-emerald-500 to-cyan-500 text-white border-transparent'
                    : 'border-emerald-500 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-900/20'
                }`}
              >
                {btn.label}
              </button>
            ))}
          </div>

          {/* Resume Buttons (primary style switches with filter) */}
          <div className="flex flex-wrap justify-center gap-3">
            <a
              href={GPU_RESUME_URL}
              aria-label="Download GPU-focused resume PDF"
              className={`px-5 py-2.5 rounded-full font-medium shadow transition-shadow ${
                primaryResume === 'GPU'
                  ? 'bg-gray-900 text-white dark:bg-white dark:text-gray-900 hover:shadow-lg'
                  : 'border border-gray-300 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800'
              }`}
            >
              Download GPU Resume
            </a>
            <a
              href={RTL_RESUME_URL}
              aria-label="Download RTL-focused resume PDF"
              className={`px-5 py-2.5 rounded-full font-medium transition-colors ${
                primaryResume === 'RTL'
                  ? 'bg-gray-900 text-white dark:bg-white dark:text-gray-900 shadow hover:shadow-lg'
                  : 'border border-gray-300 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800'
              }`}
            >
              Download RTL Resume
            </a>
          </div>
        </section>

        {/* ABOUT */}
        <section id="about" className="max-w-4xl mx-auto px-6">
          <SectionTitle>About Me</SectionTitle>
          <p className="text-lg leading-relaxed">
            I work where <strong>architecture</strong>, <strong>performance</strong>, and <strong>learning</strong> intersect.
            My interests lie in understanding how data, modeling, and design interact to shape efficient and scalable computing systems.
            I enjoy exploring how <strong>architectural insight</strong> and <strong>analytical reasoning</strong> can guide
            better design decisions—whether it’s through modeling processor behavior, optimizing workloads, or refining design methodology.
            My goal is to contribute to the next generation of computing systems that combine <strong>engineering precision</strong> with
            <strong> data-driven intuition</strong>, bridging the gap between structured design and adaptive performance.
          </p>
        </section>

        {/* PROJECTS */}
        <section id="projects" className="max-w-6xl mx-auto px-6">
          <SectionTitle>
            Featured Projects{' '}
            <span className="text-base font-normal opacity-60">({filteredProjects.length})</span>
          </SectionTitle>
          <div className="grid gap-8 md:grid-cols-2">
            {filteredProjects.map((p) => (
              <motion.a
                key={p.id}
                href={p.link}
                target={p.link?.startsWith('http') ? '_blank' : undefined}
                rel={p.link?.startsWith('http') ? 'noopener noreferrer' : undefined}
                className="group block bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm border border-gray-200 dark:border-gray-700 rounded-2xl p-6 hover:-translate-y-1 hover:shadow-xl transition transform duration-300"
                whileHover={{ scale: 1.02 }}
              >
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-xl font-bold group-hover:text-emerald-500 transition-colors">
                    {p.title}
                  </h3>
                  <span className="text-xs px-2 py-0.5 rounded-full border border-gray-300 dark:border-gray-700 opacity-80">
                    {p.category}
                  </span>
                </div>

                {/* Stack badges */}
                {p.stack?.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-3">
                    {p.stack.map((t) => (
                      <span
                        key={`${p.id}-${t}`}
                        className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-xs text-emerald-700 dark:text-emerald-300 border border-emerald-500/20"
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                )}

                <ul className="list-disc pl-5 space-y-1.5 text-sm leading-relaxed">
                  {p.bullets.map((b, i) => (
                    <li key={`${p.id}-b-${i}`}>{b}</li>
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
                key={c.title + c.subtitle}
                className="p-5 rounded-xl bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm border border-gray-200 dark:border-gray-700 shadow-sm"
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-lg font-bold">{c.title}</h3>
                <p className="text-sm opacity-80">
                  {c.subtitle} <span className="opacity-50">({c.year})</span>
                </p>
                {c.link && (
                  <a
                    href={c.link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-block mt-2 text-emerald-500 hover:underline"
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
                      key={`${bucket.title}-${item}`}
                      className="px-3 py-1 rounded-full bg-emerald-500/10 text-sm text-emerald-700 dark:text-emerald-300 border border-emerald-500/20"
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
        <section id="contact" className="max-w-md mx-auto text-center px-6">
          <SectionTitle>Let’s Connect</SectionTitle>
          <p className="mb-6 text-lg">
            Have an opportunity or want to geek out about pipelines, verification, or performance modeling? My inbox is always open.
          </p>
          <a
            href="mailto:kantamneniharshith@gmail.com"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-gradient-to-r from-fuchsia-500 to-pink-500 text-white font-medium shadow-lg hover:shadow-xl transition-shadow"
          >
            <Mail size={18} /> Say Hello
          </a>
          <div className="flex justify-center gap-6 mt-8">
            <a
              href="https://github.com/Drogon4231"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-emerald-500"
            >
              <Github size={22} />
            </a>
            <a
              href="https://linkedin.com/in/hk4231"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-emerald-500"
            >
              <Linkedin size={22} />
            </a>
          </div>
        </section>
      </main>

      {/* FOOTER */}
      <footer className="py-8 text-center text-sm opacity-70">
        © {new Date().getFullYear()} Harshith Kantamneni — Built with React ⚛︎ & TailwindCSS
      </footer>
    </div>
  );
}
