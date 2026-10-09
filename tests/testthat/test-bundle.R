test_that("transaction entries include request method and url",{
  r<-make_patient("pat-b","Bundle","Test","2000-01-01","B-1");b<-make_transaction_bundle(list(transaction_entry(r,"POST","Patient")));expect_equal(b$type,"transaction");expect_equal(b$entry[[1]]$request$method,"POST");expect_equal(b$entry[[1]]$request$url,"Patient");expect_true(validate_resource(b)$valid)
})
