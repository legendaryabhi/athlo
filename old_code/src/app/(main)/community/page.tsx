import { createClient } from '@/lib/supabase/server'
import FeedClient from './FeedClient'
import styles from './CommunityFeed.module.css'

export default async function CommunityPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  const { data: sessions, error } = await supabase
    .from('sessions')
    .select(`
      id,
      duration_seconds,
      skills_worked,
      created_at,
      photo_url,
      profiles (
        username,
        full_name,
        avatar_url,
        calisthenics_level
      ),
      likes ( user_id ),
      comments (
        id,
        content,
        created_at,
        profiles ( username )
      )
    `)
    .eq('is_private', false)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching sessions:', error)
  }

  // Format data for the client component
  const formattedSessions = (sessions || []).map((s: any) => ({
    id: s.id,
    username: s.profiles?.username || 'Unknown Athlete',
    fullName: s.profiles?.full_name || '',
    avatarUrl: s.profiles?.avatar_url || '',
    timeAgo: new Date(s.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }),
    duration: `${Math.floor(s.duration_seconds / 60)}m`,
    skills: s.skills_worked || 'General Workout',
    likesCount: s.likes ? s.likes.length : 0,
    hasLiked: s.likes ? s.likes.some((l: any) => l.user_id === user?.id) : false,
    comments: s.comments 
      ? s.comments.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()).map((c: any) => ({
          id: c.id,
          content: c.content,
          username: c.profiles?.username || 'Unknown'
        }))
      : [],
    hasPhoto: !!s.photo_url,
    photoUrl: s.photo_url,
    calisthenicsLevel: s.profiles?.calisthenics_level || '',
  }))

  return (
    <div>
      <div className={styles.header}>
        <h1 className="title">Community</h1>
      </div>
      <FeedClient initialSessions={formattedSessions} currentUserId={user?.id} />
    </div>
  )
}
