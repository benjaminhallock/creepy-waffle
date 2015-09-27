// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:

//Production
var twilio = require("twilio")("AC5ef092330a8de90da0aeb8543d8f2d44", "77a12e7d5855fb0c1cc02b61d4ed59b5");

//TEST
//var twilio = require("twilio")("ACea96b7ed8209ac7a691424cd47f4be96", "314f538b80987e6fcb5a521822b0df1d");

Parse.Cloud.define("sendVerificationCode", function(request, response) {
                   if (request.params.phoneNumber == "+10000000000") {
                   response.success("Demo Login");
                   return;
                   }

                   var verificationCode = Math.floor(Math.random()*999999);
                   var user = Parse.User.current();
                   user.set("phoneVerificationCode", verificationCode);
                   user.save();

                   twilio.sendSms({
                                  From: "7793684794",
                                  To: request.params.phoneNumber,
                                  Body: "Code: " + verificationCode
                                  }, function(err, responseData) {
                                  if (err) {
                                  response.error(err);
                                  } else {
                                  response.success("Success");
                                  }
                                  });
                   });

Parse.Cloud.define("verifyPhoneNumber", function(request, response) {
                   var user = Parse.User.current();
                   var verificationCode = user.get("phoneVerificationCode");
                   if (verificationCode == request.params.phoneVerificationCode) {
                   user.set("phoneNumber", request.params.phoneNumber);
                   user.set("isVerified", 1);
                   user.save();
                   response.success("Success");
                   } else {
                   response.error("Invalid verification code.");
                   }
                   });
