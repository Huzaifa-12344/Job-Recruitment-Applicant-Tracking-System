import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(req.method!=="POST")return new Response("Method not allowed",{status:405,headers:cors});
 const url=Deno.env.get("SUPABASE_URL")!, key=Deno.env.get("SUPABASE_ANON_KEY")!;
 const token=req.headers.get("Authorization")||"";
 const client=createClient(url,key,{global:{headers:{Authorization:token}}});
 const {data:{user},error:userError}=await client.auth.getUser();
 if(userError||!user)return new Response("Unauthorized",{status:401,headers:cors});
 try{
  const {applicationId}=await req.json();
  if(typeof applicationId!=="string")return new Response("applicationId is required",{status:400,headers:cors});
  const {data:app,error}=await client.from("applications").select("id,status,created_at,jobs(title,department),profiles(full_name)").eq("id",applicationId).eq("candidate_id",user.id).single();
  if(error||!app)return new Response("Application not found",{status:404,headers:cors});
  const hook=Deno.env.get("N8N_WEBHOOK_URL"); if(!hook)return new Response(JSON.stringify({ok:true,notification:"not_configured"}),{headers:{...cors,"Content-Type":"application/json"}});
  const secret=Deno.env.get("N8N_WEBHOOK_SECRET")||"";
  const response=await fetch(hook,{method:"POST",headers:{"Content-Type":"application/json","X-Automation-Key":secret},body:JSON.stringify({event:"application.created",applicationId:app.id,candidateId:user.id,candidateEmail:user.email,candidateName:user.user_metadata?.full_name||"",job:app.jobs})});
  if(!response.ok)return new Response("Notification service failed",{status:502,headers:cors});
  return new Response(JSON.stringify({ok:true}),{headers:{...cors,"Content-Type":"application/json"}});
 }catch{return new Response("Invalid request",{status:400,headers:cors})}
});
