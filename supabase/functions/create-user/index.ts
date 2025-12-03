import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

// Generate a secure random password
function generateSecurePassword(length: number = 12): string {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*'
  const values = crypto.getRandomValues(new Uint32Array(length))
  return Array.from(values, (value) => charset[value % charset.length]).join('')
}

Deno.serve(async (req) => {
  // Handle CORS preflight request - must be the FIRST thing checked
  // Match exact pattern from classify-pending which works
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
      },
    })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()
    let {
      email,
      password,
      firstName,
      lastName,
      role,
      phone,
      studentNumber,
      userType
    } = body || {}

    if (!email || !role) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, role' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate password if not provided (empty string or undefined/null)
    const generatedPassword = (password && password.trim() !== '') ? password : generateSecurePassword()
    const isTemporaryPassword = !password || password.trim() === ''

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
    const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    if (!SUPABASE_URL || !SERVICE_ROLE) {
      return new Response(
        JSON.stringify({ error: 'Server misconfiguration', details: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      SUPABASE_URL,
      SERVICE_ROLE
    )

    // Create auth user with metadata
    const displayName = `${firstName ?? ''} ${lastName ?? ''}`.trim()
    const { data: created, error: createErr } = await supabase.auth.admin.createUser({
      email,
      password: generatedPassword,
      email_confirm: false,
      user_metadata: {
        full_name: displayName || (email.split('@')[0] || 'User'),
        role,
        phone: phone ?? '',
        student_number: studentNumber ?? '',
        user_type: userType ?? '', // Store user type (student/teacher/security_guard)
        must_change_password: true,
        temporary_password: generatedPassword // Store actual password, not boolean
      }
    })

    if (createErr || !created?.user) {
      return new Response(
        JSON.stringify({ error: 'Failed to create auth user', details: createErr?.message || 'Unknown' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = created.user.id

    // Insert profile row
    const { data: profile, error: profileErr } = await supabase
      .from('user_profiles')
      .insert([{
        user_id: userId,
        role,
        name: displayName || (email.split('@')[0] || 'Unknown'),
        phone: phone ?? '',
        student_number: studentNumber ?? '',
        is_active: true
      }])
      .select()
      .single()

    if (profileErr) {
      return new Response(
        JSON.stringify({ error: 'User created but profile insert failed', details: profileErr.message, userId }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate verification link and send email
    let verificationLink = null
    let emailSent = false
    
    try {
      // Generate email verification link
      const redirectUrl = 'https://dres-lspu-edu-ph.456123qwert-asdf.workers.dev/login.html'
      const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
        type: 'signup',
        email: email,
        password: generatedPassword,
        options: {
          redirectTo: redirectUrl,
          data: {
            full_name: displayName || (email.split('@')[0] || 'User'),
            role,
            must_change_password: true,
            temporary_password: generatedPassword
          }
        }
      })

      if (linkData?.properties?.action_link) {
        verificationLink = linkData.properties.action_link
      }

      // Update user metadata
      await supabase.auth.admin.updateUserById(userId, {
        user_metadata: {
          full_name: displayName || (email.split('@')[0] || 'User'),
          role,
          phone: phone ?? '',
          student_number: studentNumber ?? '',
          user_type: userType ?? '',
          must_change_password: true,
          temporary_password: generatedPassword
        }
      })

      // Send invitation email via Supabase
      const { error: inviteError } = await supabase.auth.admin.inviteUserByEmail(email, {
        data: {
          full_name: displayName || (email.split('@')[0] || 'User'),
          role,
          temporary_password: generatedPassword
        },
        redirectTo: redirectUrl
      })
      
      if (!inviteError) {
        emailSent = true
        console.log('✅ Invitation email sent via Supabase')
        console.log('🔑 Password for email:', generatedPassword)
        console.log('🔗 Verification link:', verificationLink)
      } else {
        console.error('❌ Error sending invitation email:', inviteError)
      }

    } catch (emailError) {
      console.error('Email sending error (non-fatal):', emailError)
      // Continue - user is created even if email fails
    }

    return new Response(
      JSON.stringify({ 
        user: created.user, 
        profile,
        message: emailSent 
          ? 'User created successfully. Verification email sent with credentials.' 
          : 'User created successfully. Email sending failed - credentials included below.',
        email_sent: emailSent,
        password_sent: isTemporaryPassword,
        email: email,
        password: generatedPassword, // Include password directly for admin to see/share
        credentials: {
          email: email,
          password: generatedPassword,
          role: role
        },
        verification_link: verificationLink,
        note: isTemporaryPassword 
          ? `Temporary password generated: ${generatedPassword}. User should change it after first login.`
          : 'Password provided by admin. User should change it after first login.',
        setup_note: !emailSent 
          ? 'Configure RESEND_API_KEY in Supabase Edge Function secrets to send custom emails with APK download link.'
          : null
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: e.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})


