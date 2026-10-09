test_that("Patient create/read and versioning work",{
  s<-seed_store();p<-make_patient("pat-test","Test","FHIR","2000-01-01","T-1");cr<-fhir_create(s,p);expect_true(cr$success);rd<-fhir_read(s,"Patient","pat-test");expect_equal(rd$resource$id,"pat-test");p2<-rd$resource;p2$active<-FALSE;up<-fhir_update(s,p2);expect_equal(up$resource$meta$versionId,"2");expect_length(fhir_history(s,"Patient","pat-test"),2)
})
