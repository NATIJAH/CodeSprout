// Supabase Edge Function: ai-support
// Deploy this to Supabase Edge Functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message } = await req.json()
    
    if (!message) {
      return new Response(
        JSON.stringify({ error: 'Message is required' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // System prompt - explains your app
    const systemPrompt = `Anda adalah AI assistant untuk platform pembelajaran ULearn - sebuah platform pendidikan untuk guru dan murid.

TENTANG PLATFORM:
ULearn adalah platform pembelajaran dalam talian yang membolehkan guru dan murid berinteraksi, mengurus tugasan, dan berkongsi bahan pembelajaran.

FEATURES UTAMA:
1. **Dashboard** - Papan pemuka dengan kalendar dan overview aktiviti
2. **Tugasan (Tasks)** - Guru boleh assign tugasan, murid boleh submit dan tengok status
3. **Bahan Pengajaran** - Upload dan download teaching materials (PDF, docs, etc)
4. **Latihan & MCQ** - Create dan complete exercises dengan soalan objektif
5. **Chat/Messaging** - Real-time chat antara guru dan murid
6. **Kalendar** - Track dates, deadlines, dan events
7. **Activity Hub** - Tengok semua aktiviti dan updates
8. **Profile Management** - Update personal info, settings
9. **Support & Help** - FAQ, feedback system, dan AI support (you!)

USER ROLES:
- **Murid (Student)**: Boleh view tugasan, submit work, chat dengan guru, access materials
- **Guru (Teacher)**: Boleh create tugasan, upload materials, chat dengan murid, track progress

COMMON ISSUES & SOLUTIONS:
- **Login problems**: Check email/password, try reset password
- **Chat tak sampai**: Refresh page, check internet connection, pastikan notifications enabled
- **Upload fail**: Check file size (max usually 10MB), file format supported
- **Tugasan tak nampak**: Refresh dashboard, check filter/search settings
- **Notification tak muncul**: Enable browser notifications, check settings

CARA GUNA:
- **Chat**: Pergi Dashboard > Click Chat icon > Search user by email > Start conversation
- **Submit tugasan**: Dashboard > Tugasan > Pilih task > Upload file > Submit
- **View materials**: Dashboard > Bahan Pengajaran > Browse atau search
- **Create exercise (Guru)**: Dashboard > Latihan > Buat Baru > Add questions

TIPS:
- Selalu save work sebelum logout
- Check notifications regularly
- Guna search function untuk cari content
- Contact support kalau ada technical issues

Jawab soalan dalam Bahasa Melayu. Jadi helpful, friendly, dan jelas. Kalau user tanya pasal features, explain step-by-step. Kalau ada technical issue, bagi troubleshooting steps. Kalau tak pasti, suggest contact human support.`;

    // Prepare the conversation
    const prompt = `${systemPrompt}

User question: ${message}

Please provide a helpful response in Bahasa Melayu:`;

    // Call Gemini API
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: prompt
            }]
          }],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          },
        })
      }
    )

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Gemini API error:', errorText)
      throw new Error(`Gemini API error: ${geminiResponse.status}`)
    }

    const data = await geminiResponse.json()
    
    // Extract the response text
    const aiMessage = data.candidates?.[0]?.content?.parts?.[0]?.text || 
                     'Maaf, saya tidak dapat menjawab soalan ini. Sila hubungi support.'

    return new Response(
      JSON.stringify({ message: aiMessage }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: 'Maaf, berlaku ralat. Sila cuba lagi atau hubungi support.'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
