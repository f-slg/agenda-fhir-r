test_that("call-center appointment is visible through patient search",{
  s <- seed_store()
  tx <- book_appointment(s,"pat-003","Salud Completa","loc-sur","hs-cardio-sur","role-fonseca-cardio","slot-cardio-20261007-0800","first-specialist","call-center","scheduler-call-center")
  expect_true(tx$success)
  hits <- fhir_search(s,"Appointment",list(patient="pat-003"),record=FALSE)$resources
  expect_true(any(vapply(hits,function(x) identical(x$id,tx$appointment_id),logical(1))))
  app <- state_resource(s(),"Appointment",tx$appointment_id)
  expect_equal(extract_extension_value(app,APP_CONFIG$channel_extension_url),"call-center")
})
