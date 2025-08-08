import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as OneSignal from "https://esm.sh/@onesignal/node-onesignal@1.0.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// OneSignal configuration
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID")!
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY")!

const configuration = OneSignal.createConfiguration({
  appKey: ONESIGNAL_REST_API_KEY,
})
const onesignal = new OneSignal.DefaultApi(configuration)

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { title, message, playerIds, data } = await req.json()

    if (!title || !message) {
      return new Response(
        JSON.stringify({ error: 'Title and message are required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create notification object
    const notification = new OneSignal.Notification()
    notification.app_id = ONESIGNAL_APP_ID
    
    if (playerIds && playerIds.length > 0) {
      // Send to specific players
      notification.include_player_ids = playerIds
    } else {
      // Send to all subscribers
      notification.included_segments = ['All']
    }
    
    notification.headings = { en: title }
    notification.contents = { en: message }
    
    if (data) {
      notification.data = data
    }
    
    notification.android_accent_color = 'FF1976D2'
    notification.android_visibility = 1
    notification.priority = 10

    // Send notification
    const onesignalApiRes = await onesignal.createNotification(notification)
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        notificationId: onesignalApiRes.id,
        recipients: onesignalApiRes.recipients 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
    
  } catch (error) {
    console.error('Error sending notification:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to send notification' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}) 