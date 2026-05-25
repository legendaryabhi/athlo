import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import { Flame, Medal, Target, TrendingUp, Clock, Activity, Plus } from 'lucide-react';
import Link from 'next/link';
import styles from './HomeDashboard.module.css';

// Helper to normalize dates to midnight
function normalizeDate(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

// Calculate streak based on unique days worked out
function calculateStreak(sessions: any[]) {
  if (!sessions || sessions.length === 0) return 0;

  const uniqueTimes = [...new Set(sessions.map(s => normalizeDate(new Date(s.created_at))))]
    .sort((a, b) => b - a);

  const todayTime = normalizeDate(new Date());
  const oneDayMs = 24 * 60 * 60 * 1000;

  let streak = 0;
  
  if (uniqueTimes[0] === todayTime || uniqueTimes[0] === todayTime - oneDayMs) {
    streak = 1;
    let expectedNext = uniqueTimes[0] - oneDayMs;
    
    for (let i = 1; i < uniqueTimes.length; i++) {
      if (uniqueTimes[i] === expectedNext) {
        streak++;
        expectedNext -= oneDayMs;
      } else {
        break;
      }
    }
  }

  return streak;
}

export default async function HomeDashboard() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  // Fetch user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name, username')
    .eq('id', user.id)
    .single();

  const displayName = profile?.full_name || profile?.username || 'Athlete';

  // Fetch user sessions
  const { data: sessions } = await supabase
    .from('sessions')
    .select('created_at, duration_seconds')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false });

  const totalSessions = sessions?.length || 0;
  const totalDurationSeconds = sessions?.reduce((acc, s) => acc + (s.duration_seconds || 0), 0) || 0;
  const totalDurationMinutes = Math.floor(totalDurationSeconds / 60);
  const currentStreak = calculateStreak(sessions || []);

  // Today's stats
  const todayTime = normalizeDate(new Date());
  const todaySessions = sessions?.filter(s => normalizeDate(new Date(s.created_at)) === todayTime) || [];
  const todayDurationMinutes = Math.floor(todaySessions.reduce((acc, s) => acc + (s.duration_seconds || 0), 0) / 60);

  // Dynamic Milestones
  const milestones = [];
  if (totalSessions >= 1) milestones.push({ title: "First Step", desc: "Completed your first workout", icon: Target, active: true });
  if (totalSessions >= 5) milestones.push({ title: "Consistent", desc: "Completed 5 workouts", icon: Activity, active: true });
  if (totalSessions >= 10) milestones.push({ title: "Dedicated", desc: "Completed 10 workouts", icon: Flame, active: true });
  if (totalDurationSeconds >= 3600) milestones.push({ title: "Hour of Power", desc: "Trained for over 1 hour total", icon: Clock, active: true });
  
  // Add upcoming milestone
  if (totalSessions < 10 && totalSessions >= 1) {
    milestones.push({ title: "Dedicated", desc: "Complete 10 workouts", icon: Target, active: false });
  }

  const todayStr = new Date().toLocaleDateString('en-US', { day: 'numeric', month: 'long', year: 'numeric' });

  // Calculate SVG dial path length
  const circumference = Math.PI * 80; // r=80
  const maxStreak = 14; // Arbitrary scale max for visual
  const streakRatio = Math.min(currentStreak / maxStreak, 1);
  const dashoffset = circumference - (streakRatio * circumference);

  return (
    <div className={styles.dashboard}>
      <header className={styles.header}>
        <h1 className={styles.welcomeText}>Welcome, {displayName}!</h1>
        <p className={styles.dateText}>Today is {todayStr}</p>
      </header>

      {/* Streak Dial Widget */}
      <div className={`${styles.glassCard} ${styles.dialCard}`}>
        <h2 className={styles.sectionTitle} style={{ alignSelf: 'flex-start', marginBottom: 20 }}>Current Streak</h2>
        <div className={styles.dialContainer}>
          <svg className={styles.dialSvg} viewBox="0 0 200 200">
            <path 
              className={styles.dialPathBg}
              d="M 20 100 A 80 80 0 0 1 180 100"
            />
            <path 
              className={styles.dialPathFg}
              d="M 20 100 A 80 80 0 0 1 180 100"
              style={{ strokeDasharray: circumference, strokeDashoffset: dashoffset }}
            />
          </svg>
          <div className={styles.streakValue}>{currentStreak}</div>
        </div>
        <div className={styles.streakLabel}>Days in a row</div>
        <div className={styles.streakSublabel}>Keep the momentum going!</div>
      </div>

      <div className={styles.statsHeader}>
        <h2 className={styles.sectionTitle}>Today's stats</h2>
      </div>

      <div className={styles.statsGrid}>
        <div className={styles.statCard}>
          <span className={styles.statCardLabel}>Active Time</span>
          <span className={styles.statCardValue}>{todayDurationMinutes} min</span>
          <span className={styles.statCardSub}>{todaySessions.length > 0 ? 'Good effort' : 'Rest day'}</span>
        </div>
        <div className={styles.statCard}>
          <span className={styles.statCardLabel}>Total Workouts</span>
          <span className={styles.statCardValue}>{totalSessions}</span>
          <span className={styles.statCardSub}>All time</span>
        </div>
      </div>

      <div className={styles.statsHeader}>
        <h2 className={styles.sectionTitle}>Milestones</h2>
      </div>

      <div className={styles.milestoneList}>
        {milestones.length > 0 ? (
          milestones.map((m, i) => {
            const Icon = m.icon;
            return (
              <div key={i} className={styles.milestoneCard} style={{ opacity: m.active ? 1 : 0.5 }}>
                <div className={styles.milestoneIcon}>
                  <Icon size={24} color={m.active ? "var(--accent-secondary)" : "var(--text-secondary)"} />
                </div>
                <div className={styles.milestoneInfo}>
                  <div className={styles.milestoneTitle}>{m.title}</div>
                  <div className={styles.milestoneDesc}>{m.desc}</div>
                </div>
                {m.active && <Medal size={20} color="#FFD700" />}
              </div>
            );
          })
        ) : (
          <div className={styles.glassCard} style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
            Record your first session to unlock milestones!
          </div>
        )}
      </div>

      <Link href="/session" className={styles.fabButton}>
        <Plus size={32} />
      </Link>
    </div>
  );
}
