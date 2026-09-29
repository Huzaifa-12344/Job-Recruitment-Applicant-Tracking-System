import { supabase } from "./supabase";
export type AppRole = "candidate" | "recruiter" | "admin";
export async function signIn(email:string,password:string) { if(!supabase) throw new Error("Add your Supabase URL and publishable key to .env.local."); const {data,error}=await supabase.auth.signInWithPassword({email,password}); if(error) throw error; return data; }
export async function signUp(email:string,password:string,fullName:string) { if(!supabase) throw new Error("Supabase is not configured yet."); const {data,error}=await supabase.auth.signUp({email,password,options:{data:{full_name:fullName}}}); if(error) throw error; return data; }
export async function signOut() { const {error}=await supabase!.auth.signOut(); if(error) throw error; }
export async function getCurrentProfile() { const {data:{user},error:e}=await supabase!.auth.getUser(); if(e) throw e; if(!user) return null; const {data,error}=await supabase!.from("profiles").select("id,full_name,role").eq("id",user.id).single(); if(error) throw error; return data as {id:string;full_name:string;role:AppRole}; }
