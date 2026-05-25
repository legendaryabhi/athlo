'use client';

import { useState, useEffect } from 'react';
import { Heart, MessageCircle, Share2, Download, Send } from 'lucide-react';
import html2canvas from 'html2canvas';
import { createClient } from '@/lib/supabase/client';
import styles from './CommunityFeed.module.css';

export default function FeedClient({ initialSessions, currentUserId }: { initialSessions: any[], currentUserId: string | undefined }) {
  const supabase = createClient();
  const [sessions, setSessions] = useState(initialSessions);
  const [expandedComments, setExpandedComments] = useState<Set<string>>(new Set());
  const [newComment, setNewComment] = useState<{ [key: string]: string }>({});

  useEffect(() => {
    if (typeof window !== 'undefined' && window.location.hash) {
      const el = document.getElementById(window.location.hash.slice(1));
      if (el) {
        setTimeout(() => el.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100);
      }
    }
  }, []);

  const toggleLike = async (id: string, currentlyLiked: boolean) => {
    if (!currentUserId) return;

    // Optimistic UI update
    setSessions(prev => prev.map(s => {
      if (s.id === id) {
        return { 
          ...s, 
          hasLiked: !currentlyLiked, 
          likesCount: currentlyLiked ? Math.max(0, s.likesCount - 1) : s.likesCount + 1 
        };
      }
      return s;
    }));

    if (currentlyLiked) {
      await supabase.from('likes').delete().match({ session_id: id, user_id: currentUserId });
    } else {
      await supabase.from('likes').insert({ session_id: id, user_id: currentUserId });
    }
  };

  const toggleComments = (id: string) => {
    setExpandedComments(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const submitComment = async (id: string) => {
    const content = newComment[id];
    if (!content || !content.trim() || !currentUserId) return;

    // Optimistic update
    const tempComment = {
      id: Math.random().toString(),
      content: content.trim(),
      username: 'You'
    };

    setSessions(prev => prev.map(s => {
      if (s.id === id) {
        return { ...s, comments: [...(s.comments || []), tempComment] };
      }
      return s;
    }));
    setNewComment(prev => ({ ...prev, [id]: '' }));

    await supabase.from('comments').insert({
      session_id: id,
      user_id: currentUserId,
      content: content.trim()
    });
  };

  const handleShare = async (session: any) => {
    const shareUrl = `${window.location.origin}/community#session-card-${session.id}`;
    const displayName = session.fullName || session.username;
    const shareData = {
      title: `Athlo Session by ${displayName}`,
      text: `Check out this ${session.duration} workout on Athlo!`,
      url: shareUrl
    };
    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (err) {
        console.error('Error sharing:', err);
      }
    } else {
      navigator.clipboard.writeText(shareUrl);
      alert('Link copied to clipboard!');
    }
  };

  const exportAsImage = async (id: number, username: string) => {
    const frameElement = document.getElementById(`export-frame-${id}`);
    if (!frameElement) return;

    try {
      // Show export overlay and hide normal stats
      const exportOverlay = frameElement.querySelector(`.${styles.exportOverlay}`) as HTMLElement;
      const statsBar = frameElement.querySelector(`.${styles.statsBar}`) as HTMLElement;
      
      if (exportOverlay) exportOverlay.style.display = 'flex';
      if (statsBar) statsBar.style.display = 'none';

      const canvas = await html2canvas(frameElement, {
        useCORS: true,
        backgroundColor: '#000000',
        scale: 2
      });

      // Restore original visibility
      if (exportOverlay) exportOverlay.style.display = 'none';
      if (statsBar) statsBar.style.display = 'flex';

      const image = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = image;
      link.download = `athlo-session-${username.toLowerCase().replace(/\\s+/g, '-')}.png`;
      link.click();
    } catch (err) {
      console.error('Error exporting image:', err);
      alert('Failed to export image.');
    }
  };

  if (sessions.length === 0) {
    return <div style={{ textAlign: 'center', marginTop: 40, color: 'var(--text-secondary)' }}>No sessions recorded yet! Be the first.</div>
  }

  return (
    <div className={styles.feed}>
      {sessions.map((session, i) => (
        <div 
          key={session.id}
          id={`session-card-${session.id}`}
          className={styles.card}
        >
          <div className={styles.cardHeader}>
            {session.avatarUrl ? (
              <img src={session.avatarUrl} alt="Avatar" className={styles.avatar} style={{ objectFit: 'cover' }} />
            ) : (
              <div className={styles.avatar}>
                {session.username.charAt(0).toUpperCase()}
              </div>
            )}
            <div className={styles.userInfo}>
              <span className={styles.username}>{session.fullName || session.username}</span>
              <span className={styles.time}>{session.timeAgo}</span>
            </div>
          </div>

          <div className={styles.photoContainer} id={`export-frame-${session.id}`}>
            {session.hasPhoto ? (
              <img 
                src={session.photoUrl} 
                alt="Session photo" 
                style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                crossOrigin="anonymous"
                loading="lazy"
                decoding="async"
              />
            ) : (
              <div className={styles.placeholderPhoto} style={{ background: 'var(--bg-elevated)' }}>
                No Photo
              </div>
            )}

            {/* This overlay only shows during download */}
            <div className={styles.exportOverlay}>
              <div className={styles.exportTitle}>
                {session.calisthenicsLevel ? `Calisthenics ${session.calisthenicsLevel}` : 'Athlo Workout'}
              </div>
              
              <div className={styles.exportStatsGrid}>
                {session.skills && (
                  <div className={styles.exportStatItem}>
                    <span className={styles.exportStatLabel}>Skills</span>
                    <span className={styles.exportStatValue}>{session.skills}</span>
                  </div>
                )}
                <div className={styles.exportStatItem}>
                  <span className={styles.exportStatLabel}>Time</span>
                  <span className={styles.exportStatValue}>{session.duration}</span>
                </div>
              </div>

              <div className={styles.exportFooter}>
                <div className={styles.exportWatermark}>ATHLO</div>
              </div>
            </div>
            
            {/* This is the normal feed stats bar */}
            <div className={styles.statsBar}>
              <div className={styles.statItem}>
                <span className={styles.statLabel} style={{ color: 'white' }}>Workout Time</span>
                <span className={styles.statValue} style={{ color: 'white' }}>{session.duration}</span>
              </div>
              <div className={styles.statItem}>
                <span className={styles.statLabel} style={{ color: 'white' }}>Skills</span>
                <span className={styles.statValue} style={{ color: 'white' }}>{session.skills}</span>
              </div>
            </div>
          </div>

          <div className={styles.content}>
            <p className={styles.description}>
              <strong>Skills:</strong> {session.skills}
            </p>
            
            <div className={styles.actions}>
              <button 
                className={`${styles.actionBtn} ${session.hasLiked ? styles.liked : ''}`}
                onClick={() => toggleLike(session.id, session.hasLiked)}
              >
                <Heart 
                  size={20} 
                  fill={session.hasLiked ? "currentColor" : "none"} 
                />
                <span>{session.likesCount}</span>
              </button>
              <button 
                className={styles.actionBtn}
                onClick={() => toggleComments(session.id)}
              >
                <MessageCircle size={20} />
                <span>{session.comments?.length || 0}</span>
              </button>
              <button 
                className={styles.actionBtn} 
                style={{ marginLeft: 'auto' }}
                onClick={() => exportAsImage(session.id, session.username)}
                title="Export as Image"
              >
                <Download size={20} />
              </button>
              <button 
                className={styles.actionBtn}
                onClick={() => handleShare(session)}
              >
                <Share2 size={20} />
              </button>
            </div>
          </div>

          {/* Comments Section */}
          {expandedComments.has(session.id) && (
            <div className={styles.commentsSection}>
              {session.comments && session.comments.map((comment: any) => (
                <div key={comment.id} className={styles.comment}>
                  <span className={styles.commentUsername}>{comment.username}</span>
                  <span className={styles.commentContent}>{comment.content}</span>
                </div>
              ))}
              <div className={styles.commentInputWrapper}>
                <input 
                  type="text" 
                  placeholder="Add a comment..." 
                  className={styles.commentInput}
                  value={newComment[session.id] || ''}
                  onChange={(e) => setNewComment(prev => ({ ...prev, [session.id]: e.target.value }))}
                  onKeyDown={(e) => e.key === 'Enter' && submitComment(session.id)}
                />
                <button 
                  className={styles.commentSubmitBtn}
                  onClick={() => submitComment(session.id)}
                  disabled={!newComment[session.id]?.trim()}
                >
                  <Send size={18} />
                </button>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
