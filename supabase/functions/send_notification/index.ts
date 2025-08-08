// import { serve } from "https://deno.land/std@0.131.0/http/server.ts";

// serve(async (req) => {
//   try {
//     const { title, message } = await req.json();

//     const ONE_SIGNAL_APP_ID = Deno.env.get("ONE_SIGNAL_APP_ID")!;
//     const ONE_SIGNAL_REST_API_KEY = Deno.env.get("ONE_SIGNAL_REST_API_KEY")!;

//     const response = await fetch("https://onesignal.com/api/v1/notifications", {
//       method: "POST",
//       headers: {
//         "Content-Type": "application/json; charset=utf-8",
//         "Authorization": `Basic ${ONE_SIGNAL_REST_API_KEY}`,
//       },
//       body: JSON.stringify({
//         app_id: ONE_SIGNAL_APP_ID,
//         included_segments: ["All"],
//         headings: { en: title },
//         contents: { en: message },
//       }),
//     });

//     if (!response.ok) {
//       const errorText = await response.text();
//       return new Response(`Failed to send notification: ${errorText}`, { status: 500 });
//     }

//     return new Response("Notification sent successfully!", { status: 200 });
//   } catch (error) {
//     return new Response(`Error: ${error.message}`, { status: 500 });
//   }
// });
