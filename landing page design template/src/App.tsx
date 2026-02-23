import React from 'react';
import { 
  Stethoscope, Bed, Scissors, Scan, Pill, Users, Plane, HeartPulse,
  TrendingUp, ShieldAlert, Calculator, AlertTriangle, X, Check
} from 'lucide-react';

const SketchCard = ({ children, className = "", borderColor = "border-blue-900", variant = 1 }) => {
  return (
    <div className={`border-2 ${borderColor} bg-white sketch-shadow sketch-border-${variant} ${className} overflow-hidden`}>
      {children}
    </div>
  );
};

const DoodleArrow = ({ className = "" }) => (
  <svg viewBox="0 0 100 100" className={className} fill="none" stroke="currentColor" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round">
    <path d="M10,50 Q50,20 85,50 M70,35 L85,50 L65,65" />
  </svg>
);

const DoodleStar = ({ className = "" }) => (
  <svg viewBox="0 0 100 100" className={className} fill="none" stroke="currentColor" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round">
    <path d="M50,10 L60,40 L90,50 L60,60 L50,90 L40,60 L10,50 L40,40 Z" />
  </svg>
);

const DoodleUnderline = ({ className = "" }) => (
  <svg viewBox="0 0 100 20" className={className} fill="none" stroke="currentColor" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" preserveAspectRatio="none">
    <path d="M5,10 Q50,20 95,5" />
  </svg>
);

const DoodleCircle = ({ className = "" }) => (
  <svg viewBox="0 0 100 100" className={className} fill="none" stroke="currentColor" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round">
    <path d="M50,10 C80,10 90,40 80,70 C70,100 30,90 15,65 C0,40 20,10 50,10 Z" />
  </svg>
);

const CoverageItem = ({ icon: Icon, title, desc, isAdvanced, variant }) => {
  const colorClass = isAdvanced ? "bg-indigo-50 border-indigo-400" : "bg-blue-50 border-blue-400";
  const iconColor = isAdvanced ? "text-indigo-600" : "text-blue-600";
  const iconBg = isAdvanced ? "bg-indigo-100" : "bg-blue-100";

  return (
    <SketchCard variant={variant} borderColor={isAdvanced ? "border-indigo-900" : "border-blue-900"} className={`p-4 ${colorClass} hover:-translate-y-1 transition-transform cursor-pointer`}>
      <div className={`w-10 h-10 rounded-full ${iconBg} flex items-center justify-center mb-3 sketch-border-${(variant % 4) + 1} border-2 border-blue-900 ${iconColor} sketch-shadow-sm transform ${variant % 2 === 0 ? 'rotate-3' : '-rotate-3'}`}>
        <Icon size={20} strokeWidth={2.5} />
      </div>
      <h3 className="font-bold text-slate-900 mb-1">{title}</h3>
      <p className={`text-xs font-medium ${isAdvanced ? 'text-indigo-700' : 'text-blue-700'}`}>{desc}</p>
    </SketchCard>
  );
};

export default function App() {
  return (
    <div className="min-h-screen font-sans text-slate-900 selection:bg-yellow-200 relative">
      
      {/* Background Doodles */}
      <DoodleStar className="absolute top-10 left-4 w-12 h-12 text-blue-200 -rotate-12" />
      <DoodleStar className="absolute top-40 right-4 w-8 h-8 text-blue-200 rotate-45" />
      <DoodleArrow className="absolute top-1/4 -left-4 w-16 h-16 text-blue-200 rotate-90 opacity-50" />
      
      <div className="max-w-md mx-auto p-5 space-y-14 pb-20 relative z-10">
        
        {/* Header */}
        <header className="pt-8 text-center relative">
          <div className="inline-block relative">
            <h1 className="text-3xl font-black mb-2 relative z-10 text-blue-950">
              一眼看懂保障范围
            </h1>
            <DoodleUnderline className="absolute -bottom-3 left-0 w-full h-4 text-yellow-400 -z-0" />
          </div>
          <div className="mt-6 relative inline-block">
            <DoodleCircle className="absolute -inset-3 text-blue-300 -z-10 rotate-12" />
            <p className="text-blue-800 font-bold flex items-center justify-center gap-2 text-sm bg-white border-2 border-blue-900 sketch-border-2 px-4 py-2 sketch-shadow-sm transform -rotate-2">
              <span className="text-lg">🐾</span> 宠物保险通常涵盖以下项目
            </p>
          </div>
        </header>

        {/* Section 1: Coverage */}
        <section className="relative">
          <div className="grid grid-cols-2 gap-4">
            <CoverageItem variant={1} icon={Stethoscope} title="医疗门诊" desc="感冒、肠胃炎等诊症费" />
            <CoverageItem variant={2} icon={Bed} title="住院" desc="留医床位+护理" />
            <CoverageItem variant={3} icon={Scissors} title="手术" desc="开刀、麻醉等费用" />
            <CoverageItem variant={4} icon={Scan} title="检查" desc="X光、超声波、化验" />
            <CoverageItem variant={2} icon={Pill} title="药物" desc="兽医处方药" />
            <CoverageItem variant={1} icon={Users} title="第三者责任" desc="咬伤人/弄坏别人东西" isAdvanced />
            <CoverageItem variant={4} icon={Plane} title="海外旅行" desc="旅行期间保障" isAdvanced />
            <CoverageItem variant={3} icon={HeartPulse} title="癌症/慢性病" desc="长期疾病保障" isAdvanced />
          </div>
          
          <div className="flex items-center gap-6 mt-8 text-sm font-black text-blue-900 justify-center bg-white p-3 border-2 border-blue-900 sketch-border-2 sketch-shadow-sm w-max mx-auto transform rotate-1">
            <div className="flex items-center gap-2">
              <span className="w-4 h-4 rounded-full bg-blue-400 border-2 border-blue-900"></span>
              核心保障
            </div>
            <div className="flex items-center gap-2">
              <span className="w-4 h-4 rounded-full bg-indigo-400 border-2 border-blue-900"></span>
              进阶保障
            </div>
          </div>
        </section>

        {/* Section 2: 3 Steps */}
        <section>
          <div className="mb-8 relative inline-block">
            <h2 className="text-2xl font-black text-blue-950 relative z-10">
              三步选保险
            </h2>
            <div className="absolute -bottom-2 -right-4 w-12 h-12 bg-yellow-300 rounded-full mix-blend-multiply -z-10 sketch-border-3"></div>
          </div>
          
          <div className="space-y-6 relative">
            {/* Connecting line */}
            <div className="absolute left-6 top-8 bottom-8 w-0.5 border-l-4 border-dashed border-blue-300 -z-10"></div>
            
            {[
              { num: 1, title: "想清楚你最担心什么", desc: "大病手术？常常小病？咬伤人？", var: 1, color: "bg-blue-50" },
              { num: 2, title: "用 4 大指标比较", desc: "保障范围、赔偿比例、自负额、年上限", var: 3, color: "bg-blue-100" },
              { num: 3, title: "用真实情境试算", desc: "例如：一次 20,000 手术，我要付多少？", var: 2, color: "bg-blue-200" }
            ].map((step, idx) => (
              <div key={step.num} className="flex items-center gap-4 relative">
                <div className={`w-12 h-12 shrink-0 bg-blue-600 text-white rounded-full flex items-center justify-center font-black text-xl sketch-border-${(idx % 4) + 1} border-2 border-blue-900 sketch-shadow-sm transform ${idx % 2 === 0 ? '-rotate-6' : 'rotate-6'}`}>
                  {step.num}
                </div>
                <SketchCard variant={step.var} className={`p-4 flex-1 ${step.color}`}>
                  <h3 className="font-bold text-lg text-blue-950">{step.title}</h3>
                  <p className="text-blue-800 text-sm mt-1 font-medium">{step.desc}</p>
                </SketchCard>
              </div>
            ))}
          </div>
        </section>

        {/* Section 3: Key Terms */}
        <section>
          <div className="mb-8 relative inline-block">
            <h2 className="text-2xl font-black text-blue-950 relative z-10">
              关键条款对比
            </h2>
            <DoodleUnderline className="absolute -bottom-2 left-0 w-full h-3 text-emerald-400 -z-0" />
          </div>
          
          <div className="flex overflow-x-auto gap-5 pb-6 snap-x -mx-5 px-5 hide-scrollbar">
            {[
              { icon: TrendingUp, title: "赔偿比例", impact: "影响你每次自付多少", good: "≥70%, 愈高愈好", var: 2 },
              { icon: ShieldAlert, title: "年度上限", impact: "大病时会不会「报唔晒」", good: "至少覆盖一至两次大手术", var: 4 },
              { icon: Calculator, title: "自负额", impact: "小额医疗要不要自己吞", good: "常看门诊，自负额不要太高", var: 1 }
            ].map((term, idx) => (
              <SketchCard key={idx} variant={term.var} className="p-5 min-w-[260px] snap-center flex-col flex bg-emerald-50 border-blue-900">
                <div className="flex items-center gap-3 mb-5">
                  <div className={`w-12 h-12 rounded-full bg-emerald-200 flex items-center justify-center text-emerald-800 border-2 border-blue-900 sketch-border-${(idx % 4) + 1} sketch-shadow-sm transform ${idx % 2 === 0 ? 'rotate-6' : '-rotate-6'}`}>
                    <term.icon size={24} strokeWidth={2.5} />
                  </div>
                  <h3 className="font-black text-xl text-blue-950">{term.title}</h3>
                </div>
                <div className="space-y-4 flex-1">
                  <div className="bg-white p-3 border-2 border-blue-900 sketch-border-2">
                    <div className="text-xs text-slate-500 mb-1 font-black uppercase tracking-wider">对你有什么影响</div>
                    <div className="text-slate-800 font-medium">{term.impact}</div>
                  </div>
                  <div className="bg-emerald-200 p-3 border-2 border-blue-900 sketch-border-4 transform rotate-1">
                    <div className="text-xs text-emerald-800 mb-1 font-black uppercase tracking-wider">如何算「不错」</div>
                    <div className="text-emerald-950 font-black">{term.good}</div>
                  </div>
                </div>
              </SketchCard>
            ))}
          </div>
        </section>

        {/* Section 4: Not Covered */}
        <section>
          <SketchCard variant={3} className="bg-rose-50">
            <div className="p-4 border-b-2 border-blue-900 flex items-center gap-3 bg-rose-200">
              <div className="bg-white p-2 rounded-full border-2 border-blue-900 sketch-border-1 sketch-shadow-sm transform -rotate-12">
                <AlertTriangle className="text-rose-600" size={24} strokeWidth={2.5} />
              </div>
              <div>
                <h3 className="font-black text-lg text-blue-950">这些情况通常不受保</h3>
                <p className="text-rose-700 text-sm font-black">很容易踩雷 💣</p>
              </div>
            </div>
            <div className="p-5 space-y-5 relative">
              <DoodleArrow className="absolute right-4 top-10 w-12 h-12 text-rose-300 transform rotate-45" />
              {[
                { title: "既往病 & 等候期", desc: "投保前已有的疾病，以及等候期内发现的疾病通常不保" },
                { title: "日常护理", desc: "疫苗、洗牙、美容等预防性及日常护理不在保障范围" },
                { title: "配种、怀孕、主人疏忽", desc: "配种相关费用、怀孕分娩，以及主人蓄意或严重疏忽的情况" }
              ].map((item, idx) => (
                <div key={idx} className={`flex gap-3 bg-white p-3 border-2 border-blue-900 sketch-border-${(idx % 4) + 1} relative z-10`}>
                  <div className={`bg-rose-200 p-1 rounded-md border-2 border-blue-900 h-fit transform ${idx % 2 === 0 ? 'rotate-3' : '-rotate-3'}`}>
                    <X className="text-rose-700" size={16} strokeWidth={3} />
                  </div>
                  <div>
                    <h4 className="font-black text-blue-950">{item.title}</h4>
                    <p className="text-sm text-slate-600 mt-1 font-medium leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </SketchCard>
        </section>

        {/* Section 5: Why Insurance */}
        <section>
          <div className="mb-8 relative inline-block">
            <h2 className="text-2xl font-black text-blue-950 relative z-10">
              为什么需要保险？
            </h2>
            <div className="absolute -top-2 -left-4 w-10 h-10 bg-blue-200 rounded-full mix-blend-multiply -z-10 sketch-border-1"></div>
            <div className="absolute -bottom-2 -right-4 w-8 h-8 bg-yellow-200 rounded-full mix-blend-multiply -z-10 sketch-border-2"></div>
          </div>
          
          <div className="space-y-8">
            {/* No Insurance */}
            <SketchCard variant={2} className="bg-slate-100 p-5 relative">
              <div className="absolute -top-3 -right-2 bg-rose-500 text-white text-xs font-black px-3 py-1 border-2 border-blue-900 sketch-border-4 transform rotate-6 sketch-shadow-sm">
                好痛！💸
              </div>
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-full bg-slate-300 flex items-center justify-center text-slate-700 border-2 border-blue-900 sketch-border-3 sketch-shadow-sm transform -rotate-6">
                  <X size={28} strokeWidth={3} />
                </div>
                <h3 className="font-black text-xl text-blue-950">没有保险</h3>
              </div>
              <p className="text-slate-800 mb-5 font-bold bg-white p-3 border-2 border-blue-900 sketch-border-1">
                狗狗突发椎间盘问题，手术+住院 30,000
              </p>
              <div className="bg-rose-200 border-2 border-blue-900 sketch-border-4 p-4 text-rose-900 font-black flex items-center gap-2 text-lg sketch-shadow-sm transform rotate-1">
                <span>⚠️</span> 一次过全数自付：30,000 元
              </div>
            </SketchCard>

            {/* Has Insurance */}
            <SketchCard variant={4} className="bg-blue-100 p-5 relative overflow-visible">
              <div className="absolute -top-4 -right-2 bg-yellow-300 text-blue-950 text-sm font-black px-4 py-2 border-2 border-blue-900 sketch-border-1 sketch-shadow transform -rotate-6 z-10">
                省下 21,000! 🎉
              </div>
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-full bg-blue-300 flex items-center justify-center text-blue-800 border-2 border-blue-900 sketch-border-2 sketch-shadow-sm transform rotate-6">
                  <Check size={28} strokeWidth={3} />
                </div>
                <h3 className="font-black text-xl text-blue-950">有保险 (70% 保障)</h3>
              </div>
              <p className="text-slate-800 mb-5 font-bold bg-white p-3 border-2 border-blue-900 sketch-border-3">
                同一情况，手术+住院 30,000
              </p>
              
              <div className="space-y-3">
                <div className="bg-blue-200 border-2 border-blue-900 sketch-border-1 p-3 text-blue-900 flex items-center justify-between font-bold">
                  <span>保险承担：</span>
                  <span className="font-black text-lg">21,000 元</span>
                </div>
                <div className="bg-white border-2 border-blue-900 sketch-border-3 p-4 text-blue-700 font-black flex items-center justify-between sketch-shadow transform -rotate-1">
                  <div className="flex items-center gap-2">
                    <div className="bg-blue-100 p-1 rounded-full border-2 border-blue-900">
                      <Check size={16} strokeWidth={3} />
                    </div>
                    你只需自付：
                  </div>
                  <span className="font-black text-2xl">9,000 元</span>
                </div>
              </div>
            </SketchCard>
          </div>
        </section>

      </div>
    </div>
  );
}
