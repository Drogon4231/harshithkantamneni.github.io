import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Sun, Moon, Github, Linkedin, Mail } from 'lucide-react';

// ------------------------------------------
// 1 ▸ Data (projects + skills + certs)
// ------------------------------------------
const projects = [
  {
    title: 'ML-Guided CUDA Kernel Configuration',
    bullets: [
      'PyTorch MLP predicts grid / block sizes on-the-fly, boosting GEMM throughput 30% on A100 GPUs.',
      'One inference replaces exhaustive grid-search—cuts kernel-tuning time > 95%.',
      'Deployed cluster-wide via Slurm; forked by peers for benchmark suites.',
    ],
    link: 'https://github.com/Drogon4231/Ml-Guided-CUDA-Config',
  },
  {
    title: 'TDG Partition Size Prediction',
    bullets: [
      '< 5% MAE XGBoost regressor predicts runtime-optimal partition sizes for 2,000+ task graphs.',
      'Speeds simulation pipeline 25% vs. exhaustive sweeps; nightly CI now feasible.',
      'Packaged as Python API + CLI; adopted by future ECE 757 cohorts.',
    ],
    link: 'https://github.com/Drogon4231/ML-Partition-Predictor',
  },

  {
    title: '5-Stage Pipelined RISC Processor (WISC-F24)',
    bullets: [
      'Hazard-free pipeline in Verilog with full forwarding & branch prediction.',
      'Achieved 100% instruction coverage in ModelSim with cycle-accurate testbench.',
    ],
    link: '#',
  },
  {
    title: "Knight’s Tour FSM on FPGA",
    bullets: [
      'Pipelined state machine synthesizes to 333 MHz on Artix-7 (Vivado).',
      'Bluetooth-controlled via custom UART / SPI bridge.',
    ],
    link: '#',
  },
  {
    title: 'Embedded CO / CO₂ Monitoring System',
    bullets: [
      'FreeRTOS app on PSoC 6 reading SCD41 & MQ-7 via I²C / ADC.',
      'Four-layer Altium PCB streams real-time data over Ethernet.',
    ],
    link: '#',
  },
];

const certifications = [
  {
    title: 'NVIDIA Deep Learning Institute (DLI)',
    subtitle: 'Getting Started with Accelerated Computing using CUDA C++',
    year: '2025',
    link: 'https://developer.nvidia.com/dli/certificates', // update with actual cert link
  },
  {
    title: '(Upcoming) NVIDIA Deep Learning Institute (DLI)',
    subtitle: 'Deep Learning Performance for TensorRT',
    year: '2025',
  },
];

const skillBuckets = [
  {
    title: '⚙️ Hardware / RTL',
    items: ['Verilog / SystemVerilog', 'Synopsys Design Compiler', 'Static Timing Analysis'],
  },
  {
    title: '🔧 EDA / FPGA Tools',
    items: ['ModelSim', 'Intel Quartus', 'Xilinx Vivado'],
  },
  {
    title: '📈 Acceleration / GPUs',
    items: ['CUDA', 'Nsight (basic)', 'OpenMP'],
  },
  {
    title: '🧠 ML Frameworks',
    items: ['PyTorch', 'XGBoost', 'scikit-learn'],
  },
  {
    title: '💻 Languages / Systems',
    items: ['C', 'C++17', 'Python', 'Bash'],
  },
  {
    title: '📡 Embedded / PCB',
    items: ['Altium Designer', 'PSoC 6', 'I²C / SPI / UART / CAN'],
  },
];

// ------------------------------------------
const SectionTitle = ({ children }) => (
  <h2 className="text-3xl md:text-4xl font-extrabold mb-8 tracking-tight relative inline-block after:content-[''] after:absolute after:left-0 after:-bottom-2 after:w-full after:h-1 after:bg-gradient-to-r after:from-emerald-400 after:to-cyan-500 dark:after:from-emerald-500/60 dark:after:to-cyan-500/60">
    {children}
  </h2>
);

export default function Portfolio() {
  const [dark, setDark] = useState(true);

  useEffect(() => {
    const root = document.documentElement;
    dark ? root.classList.add('dark') : root.classList.remove('dark');
  }, [dark]);

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
        <section id="hero" className="relative min-h-screen flex flex-col items-center justify-center text-center px-6">
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
          <motion.p
            className="text-xl md:text-2xl max-w-2xl mb-8 leading-relaxed"
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.8 }}
          >
            Architecting intelligent hardware at the intersection of <span className="font-semibold">AI</span>, <span className="font-semibold">ML</span>, and <span className="font-semibold">high-performance compute</span>.
          </motion.p>
          <div className="flex gap-4">
            <a
              href="#projects"
              className="px-6 py-3 rounded-full bg-gradient-to-r from-emerald-500 to-cyan-500 text-white font-medium shadow-lg hover:shadow-xl transition-shadow"
            >
              See my work
            </a>
            <a
              href="https://drogon4231.github.io/harshithkantamneni.github.io/Resume.pdf"
              className="px-6 py-3 rounded-full border border-emerald-500 text-emerald-500 font-medium hover:bg-emerald-50 dark:hover:bg-emerald-950/30 transition-colors"
            >
              Resume
            </a>
          </div>
        </section>

        {/* ABOUT */}
        <section id="about" className="max-w-4xl mx-auto px-6">
          <SectionTitle>About Me</SectionTitle>
          <p className="text-lg leading-relaxed">
            I'm a graduate student in Electrical and Computer Engineering at UW–Madison (Dec 2025), focused on <strong>GPU performance optimization, CUDA programming, and ML-accelerated systems</strong>. 
            My projects span ML-guided CUDA tuning, task graph partitioning, embedded sensing, and pipelined processor design. 
            <br /><br />
            I’m completing NVIDIA Deep Learning Institute certifications on CUDA C++ and TensorRT performance, while actively seeking opportunities in <strong>Deep Learning Performance, GPU Systems Engineering, and AI hardware/software co-design.</strong>
          </p>
        </section>

        {/* PROJECTS */}
        <section id="projects" className="max-w-6xl mx-auto px-6">
          <SectionTitle>Featured Projects</SectionTitle>
          <div className="grid gap-8 md:grid-cols-2">
            {projects.map((p) => (
              <motion.a
                key={p.title}
                href={p.link}
                target="_blank"
                rel="noopener noreferrer"
                className="group block bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm border border-gray-200 dark:border-gray-700 rounded-2xl p-6 hover:-translate-y-1 hover:shadow-xl transition transform duration-300"
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-xl font-bold mb-3 group-hover:text-emerald-500 transition-colors">
                  {p.title}
                </h3>
                <ul className="list-disc pl-5 space-y-1 text-sm leading-relaxed">
                  {p.bullets.map((b) => (
                    <li key={b}>{b}</li>
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
                <p className="text-sm opacity-80">{c.subtitle} <span className="opacity-50">({c.year})</span></p>
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
                      key={item}
                      className="px-3 py-1 rounded-full bg-emerald-500/10 text-sm text-emerald-600 dark:text-emerald-400"
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
            Have an opportunity or want to geek out about GPUs? Drop a line — my inbox is always open.
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
