import { tables, seed } from './model.mjs';
const required = ['Species_Name','Tag_No','Team_Name','Name','Program_Name','Rescue_Date','Animal_ID','Team_ID','Vet_ID','Program_ID'];
const limits={Tag_No:20,Gender:10,Health_Status:30,Species_Name:100,Scientific_Name:150,Conservation_Status:50,Habitat:100,Team_Name:100,Contact_No:15,Name:100,Specialization:100,Rescue_Location:150,Rescue_Reason:200,Diagnosis:200,Treatment:300,Program_Name:100,Objective:300,Progress_Status:50};
function fail(message,status=400){throw Object.assign(new Error(message),{status});}
export function validate(table,input,partial=false){
 if(!tables[table]||table==='Animal_Audit')fail('Unknown or read-only table');
 const result={};
 for(const key of tables[table]){
  let value=input[key];
  if(partial&&value===undefined)continue;
  if(value===undefined||value===null||value===''){if(required.includes(key)||key===tables[table][0])fail(`${key.replaceAll('_',' ')} is required`);result[key]=null;continue;}
  if(key.endsWith('_ID')||['Age','Duration'].includes(key)) {value=Number(value);if(!Number.isSafeInteger(value)||value<(key.endsWith('_ID')?1:0)||value>2147483647)fail(`Invalid ${key}`);}
  else {if(typeof value!=='string')fail(`Invalid ${key}`);value=value.trim();if(required.includes(key)&&!value)fail(`${key} is required`);if(value.length>(limits[key]||300))fail(`${key} is too long`);if(key.endsWith('_Date')&&(!/^\d{4}-\d{2}-\d{2}$/.test(value)||isNaN(Date.parse(value))||new Date(value).toISOString().slice(0,10)!==value))fail(`Invalid ${key}`);}
  result[key]=value;
 }
 if(result.End_Date&&(!result.Start_Date||result.End_Date<result.Start_Date))fail('End date must be on or after start date');
 if(result.Progress_Status==='Completed'&&!result.End_Date)fail('Completed rehabilitation requires an end date');
 return result;
}
const insert=(table,record)=>({sql:`INSERT INTO ${table} (${Object.keys(record).join(',')}) VALUES (${Object.keys(record).map(()=>'?').join(',')})`,params:Object.values(record)});
export async function handle(db,method,body={}){
 if(method==='GET'){const result={};for(const t of Object.keys(tables))result[t]=await db.all(`SELECT * FROM ${t} ORDER BY ${tables[t][0]} DESC`,[]);return result;}
 if(body.action==='seed'){
  const commands=[];
  for(const [t,rows] of Object.entries(seed))for(const row of rows){const cols=tables[t];commands.push({sql:`INSERT INTO ${t} (${cols.join(',')}) SELECT ${cols.map(()=>'?').join(',')} WHERE NOT EXISTS (SELECT 1 FROM ${t} WHERE ${cols[0]} = ?)`,params:[...row,row[0]]});}
  await db.batch(commands);return {ok:true};
 }
 if(body.action==='rescue'){
  const rescue=validate('Rescue_Event',body.record||{});const cmds=[];
  if(body.animal){const animal=validate('Animal',body.animal);if(animal.Animal_ID!==rescue.Animal_ID)fail('Animal IDs must match');cmds.push(insert('Animal',animal));}
  cmds.push(insert('Rescue_Event',rescue));await db.batch(cmds);return {ok:true};
 }
 const {table,record={},id}=body;
 if(!tables[table]||table==='Animal_Audit')fail('Unknown or read-only table');
 const pk=tables[table][0];
 if(body.action==='create'){await db.batch([insert(table,validate(table,record))]);return {ok:true};}
 if(!Number.isSafeInteger(Number(id))||Number(id)<1)fail('Invalid record ID');
 const [old]=await db.all(`SELECT * FROM ${table} WHERE ${pk} = ?`,[Number(id)]);if(!old)fail('Record not found',404);
 if(body.action==='delete'){await db.batch([{sql:`DELETE FROM ${table} WHERE ${pk} = ?`,params:[Number(id)]}]);return {ok:true};}
 if(body.action==='update'){
  if(record[pk]!==undefined&&Number(record[pk])!==Number(id))fail('Primary keys cannot be changed');
  const merged=validate(table,{...old,...record});delete merged[pk];
  await db.batch([{sql:`UPDATE ${table} SET ${Object.keys(merged).map(k=>`${k} = ?`).join(',')} WHERE ${pk} = ?`,params:[...Object.values(merged),Number(id)]}]);return {ok:true};
 }
 fail('Unknown action');
}
export function errorResponse(e){const msg=String(e.message);if(e.status)return {status:e.status,message:msg};if(/foreign key/i.test(msg))return {status:409,message:'This record is linked to another record, or a selected reference no longer exists.'};if(/unique|duplicate/i.test(msg))return {status:409,message:'That ID, tag, or unique name already exists. Please choose another.'};if(/constraint/i.test(msg))return {status:400,message:'The record violates a database constraint.'};console.error(e);return {status:500,message:'Database operation failed. Please try again.'};}
