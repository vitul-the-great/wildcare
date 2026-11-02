import { env } from 'cloudflare:workers';
import { handle, errorResponse } from '../../../lib/service.mjs';
export const dynamic = 'force-dynamic';
async function run(request: Request) {
 try {
  if(request.method==='POST') {const origin=request.headers.get('origin');if(origin&&origin!==new URL(request.url).origin)return Response.json({error:'Invalid origin'},{status:403});}
  const db=env.DB!;
  const adapter={all:async(sql:string,params:unknown[]) => (await db.prepare(sql).bind(...params).all()).results,batch:async(cmds:any[])=>db.batch(cmds.map(c=>db.prepare(c.sql).bind(...c.params)))};
  return Response.json(await handle(adapter,request.method,request.method==='POST'?await request.json():{}),{headers:{'Cache-Control':'no-store'}});
 } catch(e) {const err=errorResponse(e);return Response.json({error:err.message},{status:err.status});}
}
export const GET=run;export const POST=run;
