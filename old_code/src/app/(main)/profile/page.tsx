import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProfileForm from './ProfileForm'
import FeedClient from '../community/FeedClient'

export default async function ProfilePage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Fetch profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  // Fetch user's sessions (both private and public)
  const { data: sessions, error } = await supabase
    .from('sessions')
    .select(`
      id,
      duration_seconds,
      skills_worked,
      created_at,
      photo_url,
      is_private,
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
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching sessions:', error)
  }

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
    <div style={{ paddingTop: 'var(--spacing-lg)' }}>
      <h1 className="title">Profile</h1>
      <ProfileForm 
        initialUsername={profile?.username || ''} 
        initialFullName={profile?.full_name || ''}
        initialAge={profile?.age || null}
        initialAvatarUrl={profile?.avatar_url || ''}
        initialCalisthenicsLevel={profile?.calisthenics_level || ''}
        email={user.email || ''} 
      />

      <div style={{ marginTop: 'var(--spacing-xl)' }}>
        <h2 className="title" style={{ fontSize: '1.5rem', marginBottom: 16 }}>Your Sessions</h2>
        <FeedClient initialSessions={formattedSessions} currentUserId={user.id} />
      </div>
    </div>
  )
}
