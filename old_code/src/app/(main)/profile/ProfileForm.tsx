'use client';

import { useState } from 'react';
import { updateProfile, logout } from './actions'
import { LogOut, Save, Camera } from 'lucide-react'
import { createClient } from '@/lib/supabase/client';

export default function ProfileForm({ 
  initialUsername, 
  initialFullName,
  initialAge,
  initialAvatarUrl,
  initialCalisthenicsLevel,
  email 
}: { 
  initialUsername: string, 
  initialFullName: string,
  initialAge: number | null,
  initialAvatarUrl: string,
  initialCalisthenicsLevel: string,
  email: string 
}) {
  const [avatarUrl, setAvatarUrl] = useState(initialAvatarUrl || '');
  const [isUploading, setIsUploading] = useState(false);

  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const supabase = createClient();
    const fileExt = file.name.split('.').pop();
    const fileName = `${Math.random()}.${fileExt}`;
    
    const { error: uploadError } = await supabase.storage
      .from('photos')
      .upload(fileName, file);

    if (uploadError) {
      alert('Failed to upload photo: ' + uploadError.message);
      setIsUploading(false);
      return;
    }

    const { data } = supabase.storage.from('photos').getPublicUrl(fileName);
    setAvatarUrl(data.publicUrl);
    setIsUploading(false);
  };

  return (
    <div className="card">
      <div style={{ marginBottom: 24, display: 'flex', alignItems: 'center', gap: 16 }}>
        <div style={{ position: 'relative', width: 64, height: 64, borderRadius: '50%', backgroundColor: 'var(--bg-elevated)', overflow: 'hidden' }}>
          {avatarUrl ? (
            <img src={avatarUrl} alt="Avatar" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Camera size={24} />
            </div>
          )}
          <input 
            type="file" 
            accept="image/*" 
            onChange={handleAvatarUpload}
            style={{ position: 'absolute', inset: 0, opacity: 0, cursor: 'pointer' }}
          />
        </div>
        <div>
          <p className="subtitle" style={{ marginBottom: 4 }}>Account Email</p>
          <p style={{ fontWeight: 600 }}>{email}</p>
        </div>
      </div>

      <form action={updateProfile} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <input type="hidden" name="avatarUrl" value={avatarUrl} />
        
        <div>
          <label className="subtitle" style={{ display: 'block', marginBottom: 8 }}>Username</label>
          <input 
            className="input" 
            name="username" 
            defaultValue={initialUsername} 
            placeholder="Choose a username..." 
          />
        </div>

        <div>
          <label className="subtitle" style={{ display: 'block', marginBottom: 8 }}>Full Name</label>
          <input 
            className="input" 
            name="fullName" 
            defaultValue={initialFullName} 
            placeholder="Your full name..." 
          />
        </div>

        <div>
          <label className="subtitle" style={{ display: 'block', marginBottom: 8 }}>Age</label>
          <input 
            className="input" 
            type="number"
            name="age" 
            defaultValue={initialAge || ''} 
            placeholder="Your age..." 
          />
        </div>

        <div>
          <label className="subtitle" style={{ display: 'block', marginBottom: 8 }}>Calisthenics Level</label>
          <input 
            className="input" 
            name="calisthenicsLevel" 
            defaultValue={initialCalisthenicsLevel} 
            placeholder="e.g. Intermediate" 
          />
        </div>
        
        <button className="btn-primary" type="submit" style={{ gap: 8 }} disabled={isUploading}>
          <Save size={20} />
          {isUploading ? 'Uploading...' : 'Save Profile'}
        </button>
      </form>

      <div style={{ marginTop: 32, paddingTop: 32, borderTop: '1px solid var(--border-color)' }}>
        <form action={logout}>
          <button className="btn-secondary" style={{ color: '#ff3333', gap: 8 }}>
            <LogOut size={20} />
            Log Out
          </button>
        </form>
      </div>
    </div>
  )
}
