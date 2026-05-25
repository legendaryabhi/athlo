import { login, signup } from './actions'

export default async function LoginPage(props: { searchParams: Promise<{ error?: string }> }) {
  const searchParams = await props.searchParams;
  const error = searchParams.error;

  return (
    <div className="auth-container">
      <div className="card" style={{ maxWidth: 400, margin: '0 auto', width: '100%' }}>
        <h1 className="title" style={{ textAlign: 'center', marginBottom: 8 }}>Athlo</h1>
        <p className="subtitle" style={{ textAlign: 'center', marginBottom: 32 }}>Welcome to your calisthenics journey.</p>
        
        {error && (
          <div style={{ padding: 12, backgroundColor: 'rgba(255, 51, 51, 0.1)', color: '#ff3333', borderRadius: 12, marginBottom: 16, fontSize: '0.875rem' }}>
            {error}
          </div>
        )}

        <form>
          <input
            className="input"
            id="email"
            name="email"
            type="email"
            placeholder="Email address"
            required
          />
          <input
            className="input"
            id="password"
            name="password"
            type="password"
            placeholder="Password"
            required
          />

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 24 }}>
            <button formAction={login} className="btn-primary">
              Log In
            </button>
            <button formAction={signup} className="btn-secondary">
              Sign Up
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
