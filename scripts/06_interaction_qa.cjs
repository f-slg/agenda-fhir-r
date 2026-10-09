const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs'),path=require('path');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.QA_BROWSER,headless:true,args:['--no-sandbox']});
 const context=await browser.newContext({viewport:{width:1366,height:768},permissions:['clipboard-read','clipboard-write']});
 const page=await context.newPage();const results=[];const out=path.resolve('docs/qa-responsive');
 const tab=async name=>{await page.locator('.navbar').getByRole('tab',{name,exact:true}).click();await page.waitForTimeout(700)};
 await page.goto('http://127.0.0.1:3838');await page.waitForTimeout(1800);
 await tab('Portal Paciente');await page.locator('#patient-search_slots').click();
 await page.locator('#patient-slot_cards input').first().waitFor({state:'visible'});
 await page.locator('#patient-book_selected').click();
 await page.getByText('Cita confirmada',{exact:true}).waitFor();
 const id=(await page.locator('#patient-booking_result small').innerText()).split('Appointment/')[1];
 results.push({check:'Patient booking',pass:!!id});
 await page.screenshot({path:path.join(out,'1366-reserva-confirmada.png'),fullPage:true});
 await tab('Agendador');await page.locator('#scheduler-appointments input[type=search]').fill(id);
 const row=page.locator('#scheduler-appointments tbody tr').filter({hasText:id});await row.click();
 await page.locator('#scheduler-selected_info .status-booked').waitFor();
 await page.locator('#scheduler-cancel').click();await page.getByText('Cita cancelada; Slot liberado',{exact:true}).waitFor();await page.waitForTimeout(500);await page.locator('#scheduler-appointments input[type=search]').fill(id);await row.click();await page.locator('#scheduler-selected_info .status-cancelled').waitFor();
 results.push({check:'Shared Appointment selection and cancellation',pass:true});
 await tab('Portal Clínico');
 await page.locator('#clinician-agenda tbody tr').filter({hasText:'booked'}).first().click();
 await page.locator('#clinician-start').click();await page.locator('#clinician-encounter_info .status-in-progress').waitFor();
 await page.locator('#clinician-prepare').click();await page.locator('#clinician-transaction_preview .json-view').waitFor();
 await page.locator('#clinician-process').click();await page.locator('#clinician-encounter_info .status-finished').waitFor();
 results.push({check:'Encounter + clinical Bundle transaction',pass:true});
 await page.screenshot({path:path.join(out,'1366-atencion-finalizada.png'),fullPage:true});
 await tab('FHIR Studio');await page.locator('#studio-resources-table tbody tr').first().click();
 await page.getByRole('tab',{name:'JSON',exact:true}).click();await page.waitForTimeout(500);
 await page.getByRole('button',{name:'Copiar JSON',exact:true}).click();await page.getByText('JSON copiado',{exact:true}).waitFor();
 const clipboard=await page.evaluate(()=>navigator.clipboard.readText());JSON.parse(clipboard);
 const downloadPromise=page.waitForEvent('download');await page.locator('#studio-json-download').click();const download=await downloadPromise;
 results.push({check:'JSON clipboard and download',pass:!await download.failure()});
 await page.goto('file://'+path.join(out,'calendar-stress.html'));
 for(const [w,h] of [[1920,1080],[1600,900],[1440,900],[1366,768],[1280,800],[1024,768]]){
  await page.setViewportSize({width:w,height:h});
  const geometry=await page.evaluate(()=>{
   const events=[...document.querySelectorAll('.week-event')].map(e=>e.getBoundingClientRect());let overlaps=0;
   for(let i=0;i<events.length;i++)for(let j=i+1;j<events.length;j++){const a=events[i],b=events[j];if(a.left<b.right-.5&&b.left<a.right-.5&&a.top<b.bottom-.5&&b.top<a.bottom-.5)overlaps++}
   return {events:events.length,overlaps,globalOverflow:document.documentElement.scrollWidth>innerWidth+1};
  });
  results.push({check:`Concurrent calendar ${w}x${h}`,pass:geometry.events===15&&geometry.overlaps===0&&!geometry.globalOverflow,...geometry});
 }
 fs.writeFileSync(path.join(out,'interactions.json'),JSON.stringify(results,null,2));console.log(JSON.stringify(results,null,2));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
