'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Home, ClipboardList, User, Activity } from 'lucide-react';
import styles from './BottomNavigation.module.css';

export default function BottomNavigation() {
  const pathname = usePathname();
  const navItems = [
    { href: '/home', label: 'Home', icon: Home },
    { href: '/community', label: 'Feed', icon: ClipboardList },
    { href: '/profile', label: 'Profile', icon: User },
  ];

  return (
    <nav className={styles.navContainer}>
      {navItems.map((item) => {
        const isActive = pathname === item.href;
        const Icon = item.icon;

        return (
          <Link href={item.href} key={item.href} className={`${styles.navItem} ${isActive ? styles.active : ''}`}>
            <div className={styles.iconContainer}>
              <Icon size={20} />
            </div>
            <AnimatePresence>
              {isActive && (
                <motion.span 
                  className={styles.label}
                  initial={{ width: 0, opacity: 0 }}
                  animate={{ width: 'auto', opacity: 1 }}
                  exit={{ width: 0, opacity: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  {item.label}
                </motion.span>
              )}
            </AnimatePresence>
          </Link>
        );
      })}
    </nav>
  );
}
