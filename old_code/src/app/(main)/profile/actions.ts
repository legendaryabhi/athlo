'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

export async function updateProfile(formData: FormData) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return

  const username = formData.get('username') as string
  const fullName = formData.get('fullName') as string
  const ageStr = formData.get('age') as string
  const age = ageStr ? parseInt(ageStr, 10) : null
  const avatarUrl = formData.get('avatarUrl') as string
  const calisthenicsLevel = formData.get('calisthenicsLevel') as string

  await supabase
    .from('profiles')
    .upsert({
      id: user.id,
      username,
      full_name: fullName,
      age: age,
      avatar_url: avatarUrl || undefined,
      calisthenics_level: calisthenicsLevel || undefined,
    })

  revalidatePath('/profile')
}

export async function logout() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/login')
}
