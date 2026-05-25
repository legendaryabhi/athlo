'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Camera, Image as ImageIcon, UploadCloud } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import imageCompression from 'browser-image-compression';
import styles from './SessionTracker.module.css';

export default function SessionPage() {
  const [isActive, setIsActive] = useState(false);
  const [time, setTime] = useState(0);
  const [showModal, setShowModal] = useState(false);
  
  // Modal form state
  const [skills, setSkills] = useState('');
  const [photo, setPhoto] = useState<File | null>(null);
  const [isPrivate, setIsPrivate] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  const timerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (isActive) {
      timerRef.current = setInterval(() => {
        setTime((t) => t + 1);
      }, 1000);
    } else {
      if (timerRef.current) clearInterval(timerRef.current);
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isActive]);

  const toggleSession = () => {
    if (isActive) {
      setIsActive(false);
      setShowModal(true);
    } else {
      setTime(0);
      setIsActive(true);
      setSkills('');
      setPhoto(null);
    }
  };

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const handleSave = async () => {
    setIsSaving(true);
    let photoUrl = null;

    if (photo) {
      try {
        const options = {
          maxSizeMB: 1,
          maxWidthOrHeight: 1920,
          useWebWorker: true,
        };
        const compressedFile = await imageCompression(photo, options);

        const supabase = createClient();
        const fileExt = compressedFile.name.split('.').pop() || 'jpg';
        const fileName = `${Math.random()}.${fileExt}`;
        const filePath = `${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('photos')
          .upload(filePath, compressedFile);

        if (uploadError) {
          alert('Failed to upload photo: ' + uploadError.message);
          setIsSaving(false);
          return;
        }

        const { data } = supabase.storage.from('photos').getPublicUrl(filePath);
        photoUrl = data.publicUrl;
      } catch (err) {
        console.error('Compression error:', err);
        alert('Failed to process image due to low memory. Try a smaller photo.');
        setIsSaving(false);
        return;
      }
    }

    const { saveSession } = await import('./actions');
    const result = await saveSession(time, skills, photoUrl, isPrivate);
    
    setIsSaving(false);
    if (result.error) {
      alert('Failed to save session: ' + result.error);
    } else {
      setShowModal(false);
      setTime(0);
      setSkills('');
      setPhoto(null);
      setIsPrivate(false);
      // Optional: redirect to community
    }
  };

  return (
    <div className={styles.container}>
      <motion.div 
        className={styles.timer}
        animate={{ scale: isActive ? 1.05 : 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 10 }}
      >
        {formatTime(time)}
      </motion.div>

      <motion.button
        className={`${styles.startButton} ${isActive ? styles.active : ''}`}
        onClick={toggleSession}
        whileTap={{ scale: 0.95 }}
      >
        <div className={styles.buttonInner}>
          {isActive ? 'Stop' : 'Start'}
        </div>
      </motion.button>

      <AnimatePresence>
        {showModal && (
          <motion.div 
            className={styles.modalOverlay}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div 
              className={styles.modalContent}
              initial={{ y: 50, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 50, opacity: 0 }}
            >
              <h2 className={styles.modalTitle}>Share Session</h2>
              
              <label className={styles.label}>What did you work on?</label>
              <textarea 
                className={styles.textarea} 
                placeholder="Planche progressions, front lever holds..."
                value={skills}
                onChange={(e) => setSkills(e.target.value)}
              />

              <label className={styles.label}>Add a Photo</label>
              <label className={styles.fileLabel}>
                <input 
                  type="file" 
                  accept="image/*" 
                  className={styles.fileInput}
                  onChange={(e) => setPhoto(e.target.files?.[0] || null)}
                />
                <UploadCloud size={24} />
                <span>{photo ? 'Photo Selected' : 'Upload photo'}</span>
              </label>

              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
                <input 
                  type="checkbox" 
                  id="isPrivate" 
                  checked={isPrivate} 
                  onChange={(e) => setIsPrivate(e.target.checked)} 
                />
                <label style={{ color: '#ffffff' }} htmlFor="isPrivate">Keep this session private</label>
              </div>

              <div className={styles.buttonGroup}>
                <button className={styles.btnCancel} onClick={() => setShowModal(false)} disabled={isSaving}>
                  Cancel
                </button>
                <button className="btn-primary" onClick={handleSave} style={{ flex: 2 }} disabled={isSaving}>
                  {isSaving ? 'Sharing...' : (isPrivate ? 'Save Private Session' : 'Share to Community')}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
