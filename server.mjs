import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import mysql from 'mysql2/promise';
import {handle,errorResponse} from '../lib/service.mjs';
const pool=mysql.createPool({host:process.env.DB_HOST||'127.0.0.1',port:Number(process.env.DB_PORT||3306),user:process.env.DB_USER,password:process.env.DB_PASSWORD,database:process.env.DB_NAME||'WildlifeDB',dateStrings:true,connectionLimit:5});
const db={all:async(sql,params)=>(await pool.execute(sql,params))[0],batch:async(commands)=>{const c=await pool.getConnection();try{await c.beginTransaction();for(const {sql,params} of commands)await c.execute(sql,params);await c.commit()}catch(e){await c.rollback();throw e}finally{c.release()}}};
const root=path.resolve(import.meta.dirname,'dist');const port=Number(process.env.PORT||3001);
http.createServer(async(req,res)=>{
 const url=new URL(req.url,'http://localhost');
 if(url.pathname==='/api/data'){
  res.setHeader('Content-Type','application/json');res.setHeader('Cache-Control','no-store');
  if(!['GET','POST'].includes(req.method)){res.writeHead(405).end(JSON.stringify({error:'Method not allowed'}));return;}
  try{
   if(req.method==='POST'&&req.headers.origin&&!['http://localhost:5173','http://127.0.0.1:5173',`http://localhost:${port}`,`http://127.0.0.1:${port}`].includes(req.headers.origin))throw Object.assign(Error('Invalid origin'),{status:403});
   let raw='';for await(const chunk of req){raw+=chunk;if(raw.length>65536)throw Object.assign(Error('Request too large'),{status:413})}
   let body={};try{body=raw?JSON.parse(raw):{}}catch{throw Object.assign(Error('Invalid JSON'),{status:400})}
   res.end(JSON.stringify(await handle(db,req.method,body)));
  }catch(e){const err=errorResponse(e);res.writeHead(err.status).end(JSON.stringify({error:err.message}))}return;
 }
 try{let file=path.resolve(root,'.'+decodeURIComponent(url.pathname));if(!file.startsWith(root+path.sep)&&file!==root){res.writeHead(403).end();return}if(url.pathname==='/'||!path.extname(file))file=path.join(root,'index.html');const buf=await fs.readFile(file);const types={'.html':'text/html','.js':'text/javascript','.css':'text/css','.svg':'image/svg+xml','.zip':'application/zip'};res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');res.end(buf)}catch{res.writeHead(404).end('Not found. Run npm run build in local/ first.')}
}).listen(port,'127.0.0.1',()=>console.log(`Wildcare running at http://127.0.0.1:${port}`));
