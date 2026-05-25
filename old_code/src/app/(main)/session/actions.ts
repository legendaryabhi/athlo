'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function saveSession(durationSeconds: number, skills: string, photoUrl: string | null = null, isPrivate: boolean = false) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Not authenticated' }
  }

  const endTime = new Date()
  const startTime = new Date(endTime.getTime() - durationSeconds * 1000)

  const { error } = await supabase
    .from('sessions')
    .insert({
      user_id: user.id,
      start_time: startTime.toISOString(),
      end_time: endTime.toISOString(),
      duration_seconds: durationSeconds,
      skills_worked: skills,
      photo_url: photoUrl,
      is_private: isPrivate
    })

  if (error) {
    console.error('Error saving session:', error)
    return { error: error.message }
  }

  revalidatePath('/community')
  return { success: true }
}
