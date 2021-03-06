
#import "RNCAppleAuthentication.h"
#import <React/RCTUtils.h>

@implementation RNCAppleAuthentication

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()


- (NSDictionary *)constantsToExport
{
  NSDictionary* scopes = @{@"FULL_NAME": ASAuthorizationScopeFullName, @"EMAIL": ASAuthorizationScopeEmail};
  NSDictionary* operations = @{
    @"LOGIN": ASAuthorizationOperationLogin,
    @"REFRESH": ASAuthorizationOperationRefresh,
    @"LOGOUT": ASAuthorizationOperationLogout,
    @"IMPLICIT": ASAuthorizationOperationImplicit
  };
  NSDictionary* credentialStates = @{
    @"AUTHORIZED": @(ASAuthorizationAppleIDProviderCredentialAuthorized),
    @"REVOKED": @(ASAuthorizationAppleIDProviderCredentialRevoked),
    @"NOT_FOUND": @(ASAuthorizationAppleIDProviderCredentialNotFound),
  };
  NSDictionary* userDetectionStatuses = @{
    @"LIKELY_REAL": @(ASUserDetectionStatusLikelyReal),
    @"UNKNOWN": @(ASUserDetectionStatusUnknown),
    @"UNSUPPORTED": @(ASUserDetectionStatusUnsupported),
  };
  
  return @{
           @"Scope": scopes,
           @"Operation": operations,
           @"CredentialState": credentialStates,
           @"UserDetectionStatus": userDetectionStatuses
           };
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

RCT_EXPORT_METHOD(requestAsync:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  _promiseResolve = resolve;
  _promiseReject = reject;
  
  ASAuthorizationAppleIDProvider* appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
  ASAuthorizationAppleIDRequest* request = [appleIDProvider createRequest];
  //request.requestedScopes = options[@"requestedScopes"];
  request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
  if (options[@"requestedOperation"]) {
    request.requestedOperation = options[@"requestedOperation"];
  }
  
  ASAuthorizationController* ctrl = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
  ctrl.presentationContextProvider = self;
  ctrl.delegate = self;
  [ctrl performRequests];
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
  return RCTKeyWindow();
}

- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization {
    
            ASAuthorizationAppleIDCredential * credential = authorization.credential;
           
           // ??????????????????????????????????????????????????????????????????????????? App ?????????????????????????????????????????????????????????????????????????????????????????????????????????
           NSString * userID = credential.user;
           
           //?????????????????? ???????????????????????????????????????????????????
           NSPersonNameComponents * fullName = credential.fullName;
           NSString * email = credential.email;
           
           // ????????????????????????????????????
           NSString * authorizationCode = [[NSString alloc] initWithData:credential.authorizationCode encoding:NSUTF8StringEncoding];
           NSString * identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding];
           
           // ?????????????????????????????????????????????????????????????????????????????????unsupported???unknown???likelyReal
           ASUserDetectionStatus realUserStatus = credential.realUserStatus;
           
           [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"appleID"];
    
          NSDictionary* user = @{
                                 @"fullName": RCTNullIfNil(fullName),
                                 @"email": RCTNullIfNil(email),
                                 @"user": userID,
                                 @"authorizedScopes": credential.authorizedScopes,
                                 @"realUserStatus": @(realUserStatus),
                                 @"state": RCTNullIfNil(credential.state),
                                 @"authorizationCode": RCTNullIfNil(authorizationCode),
                                 @"identityToken": RCTNullIfNil(identityToken)
                                 };
          _promiseResolve(user);
}

- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error {
  _promiseReject(@"RNCAppleSignIn", error.description, error);
}

@end
  
