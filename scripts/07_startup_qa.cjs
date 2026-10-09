// Run both servers first: runApp(source('app.R')$value) and runApp('.').
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.QA_BROWSER,headless:true,args:['--no-sandbox']});
 const out='docs/qa-startup';fs.mkdirSync(out,{recursive:true});const results=[];
 for(const [mode,url] of [['object',process.env.QA_OBJECT_URL||'http://127.0.0.1:3841'],['directory',process.env.QA_DIRECTORY_URL||'http://127.0.0.1:3842']]){
  const context=await browser.newContext({permissions:['clipboard-read','clipboard-write']});const page=await context.newPage();const errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
  await page.goto(url);await page.waitForFunction(()=>document.querySelector('#home-n_patient')?.textContent==='10');
  for(const [width,height] of [[1920,1080],[1600,900],[1440,900],[1366,768],[1280,800],[1024,768]]){
   await page.setViewportSize({width,height});
   const state=await page.evaluate(()=>({grid:getComputedStyle(document.querySelector('.hero-grid')).display,logoLoaded:document.querySelector('.brand-logo').complete&&document.querySelector('.brand-logo').naturalWidth>0,team:document.querySelector('.brand').textContent.trim(),overflow:document.documentElement.scrollWidth>innerWidth}));
   results.push({mode,width,height,...state,pass:state.grid==='grid'&&state.logoLoaded&&state.team==='FHIR TEAM'&&!state.overflow});
  }
  await page.setViewportSize({width:1366,height:768});await page.screenshot({path:`${out}/${mode}-home.png`,fullPage:true});
  await page.getByRole('tab',{name:'Agendador',exact:true}).click();await page.locator('#scheduler-weekly_agenda .week-calendar-board').waitFor();
  await page.screenshot({path:`${out}/${mode}-agenda.png`,fullPage:true});
  await page.getByRole('tab',{name:'FHIR Studio',exact:true}).click();await page.locator('#studio-resources-table tbody tr').first().click();
  await page.getByRole('tab',{name:'JSON',exact:true}).click();await page.waitForFunction(()=>document.querySelector('#studio-json-json')?.textContent.includes('resourceType'));
  await page.getByRole('button',{name:'Copiar JSON',exact:true}).click();await page.getByText('JSON copiado',{exact:true}).waitFor();
  const copied=JSON.parse(await page.evaluate(()=>navigator.clipboard.readText()));results.push({mode,check:'inline JS, clipboard and HTTP resources',pass:!!copied.resourceType&&!errors.length,errors});
  await context.close();
 }
 await browser.close();fs.writeFileSync(`${out}/results.json`,JSON.stringify(results,null,2));console.log(JSON.stringify(results,null,2));if(results.some(r=>!r.pass))process.exit(1);
})().catch(e=>{console.error(e);process.exit(1)});
