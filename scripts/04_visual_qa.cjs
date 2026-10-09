// Development-only browser QA. Uses an existing Playwright installation, not an app dependency.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs');
const path=require('path');
const out=path.resolve('docs/qa-responsive');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.QA_BROWSER || undefined,args:['--no-sandbox']});
 const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.status()>=400) errors.push(`HTTP ${r.status()}: ${r.url()}`)});
 const results=[];
 const tabs=['Inicio','Portal Paciente','Agendador','Portal Clínico','FHIR Studio','AI Copilot'];
 async function audit(name,w,h){
  await page.waitForTimeout(400);
  const data=await page.evaluate(()=>{
   const visible=e=>!!(e.offsetWidth||e.offsetHeight||e.getClientRects().length);
   const boxes=[...document.querySelectorAll('.week-event')].filter(visible);
   let overlaps=0;
   for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){
    const a=boxes[i].getBoundingClientRect(),b=boxes[j].getBoundingClientRect();
    if(a.left<b.right-.5&&b.left<a.right-.5&&a.top<b.bottom-.5&&b.top<a.bottom-.5)overlaps++;
   }
   let panels=0;
   for(const grid of document.querySelectorAll('.responsive-grid,.clinical-command-grid,.metric-grid,.kpi-strip,.mini-calendar')){
    const children=[...grid.children].filter(visible);
    for(let i=0;i<children.length;i++)for(let j=i+1;j<children.length;j++){
     const a=children[i].getBoundingClientRect(),b=children[j].getBoundingClientRect();
     if(a.left<b.right-.5&&b.left<a.right-.5&&a.top<b.bottom-.5&&b.top<a.bottom-.5)panels++;
    }
   }
   return {customStylesLoaded:getComputedStyle(document.querySelector(".hero-grid")).display==="grid",documentWidth:document.documentElement.scrollWidth,viewport:innerWidth,globalOverflow:document.documentElement.scrollWidth>innerWidth+1,eventCount:boxes.length,eventOverlaps:overlaps,panelOverlaps:panels,shinyErrors:[...document.querySelectorAll('.shiny-output-error')].filter(visible).map(x=>x.textContent)};
  });
  results.push({resolution:`${w}x${h}`,screen:name,...data});
  await page.screenshot({path:path.join(out,`${w}-${name}.png`),fullPage:true});
 }
 for(const [w,h] of [[1920,1080],[1600,900],[1440,900],[1366,768],[1280,800],[1024,768]]){
  await page.setViewportSize({width:w,height:h});
  await page.goto(process.env.QA_URL || 'http://127.0.0.1:3838');
  await page.waitForFunction(()=>window.Shiny&&Shiny.shinyapp&&Shiny.shinyapp.$socket?.readyState===1);
  await page.waitForTimeout(1000);
  for(let i=0;i<tabs.length;i++){
   await page.locator('.navbar').getByRole('tab',{name:tabs[i],exact:true}).click();
   if(i===1){await page.waitForTimeout(800);await page.getByRole('button',{name:'Consultar disponibilidad',exact:true}).click();await page.waitForTimeout(700);await page.locator('#patient-slot_cards input[type=radio]').first().waitFor({state:'visible'});}
   if(i===2){await page.locator('#scheduler-appointments tbody tr').first().click();await page.waitForTimeout(300);}
   await audit(['home','paciente','agenda','clinico','studio','copilot'][i],w,h);
   if(i===4){
    await page.locator('#studio-resources-table tbody tr').first().click();
    await page.getByRole('tab',{name:'JSON',exact:true}).click();await page.waitForTimeout(300);await audit('json',w,h);
    for(const tab of ['Graph','Transactions','REST Trace','Validation','History','Audit','Capability','Architecture']){
     await page.getByRole('tab',{name:tab,exact:true}).click();await page.waitForTimeout(300);await audit('studio-'+tab.replaceAll(' ','-').toLowerCase(),w,h);
    }
   }
  }
 }
 fs.writeFileSync(path.join(out,'measurements.json'),JSON.stringify({results,errors},null,2));
 console.log(JSON.stringify({screens:results.length,failures:results.filter(r=>!r.customStylesLoaded||r.globalOverflow||r.eventOverlaps||r.panelOverlaps||r.shinyErrors.length),errors},null,2));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
