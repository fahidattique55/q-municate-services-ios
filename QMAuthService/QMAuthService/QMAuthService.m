//
//  QMBaseAuthService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 29.10.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMAuthService.h"

@interface QMAuthService()

@property (assign, nonatomic) BOOL isAuthorized;

@end

@implementation QMAuthService

- (QBRequest *)logOut:(void(^)(QBResponse *response))completion {
    
    __weak __typeof(self)weakSelf = self;
    QBRequest *request =
    [QBRequest logOutWithSuccessBlock:^(QBResponse *response) {
        
        weakSelf.isAuthorized = NO;
        
        if (completion)
            completion(response);
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf showMessageForQBResponce:response];
        
        if (completion)
            completion(response);
    }];
    
    return request;
}

- (QBRequest *)signUpAndLoginWithUser:(QBUUser *)user
                           completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    QBRequest *request =
    
    [QBRequest signUp:user
         successBlock:^(QBResponse *response, QBUUser *newUser) {
             
             [weakSelf logInWithUser:user
                          completion:^(QBResponse *logInResponse,
                                       QBUUser *userProfile) {
                              
                              weakSelf.isAuthorized = YES;
                              completion(logInResponse, userProfile);
                          }];
             
         } errorBlock:^(QBResponse *response) {
             
             [weakSelf showMessageForQBResponce:response];
             
             if (completion)
                 completion(response, nil);
         }];
    
    return request;
}

#pragma mark - Private methods

- (QBRequest *)logInWithUser:(QBUUser *)user
                  completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion {
    
    __weak __typeof(self)weakSelf = self;
    //Common error block
    void (^errorBlock)(id) = ^(QBResponse *response){
        
        [weakSelf showMessageForQBResponce:response];
        completion(response, nil);
    };
    
    void (^successBlock)(id, id) = ^(QBResponse *response, QBUUser *userProfile){
        
        weakSelf.isAuthorized = YES;
        completion(response, userProfile);
    };
    
    QBRequest *request = nil;
    
    if (user.email) {
        
        request =
        [QBRequest logInWithUserEmail:user.email
                             password:user.password
                         successBlock:successBlock
                           errorBlock:errorBlock];
    }
    else if (user.login) {
        
        request =
        [QBRequest logInWithUserLogin:user.login
                             password:user.password
                         successBlock:successBlock
                           errorBlock:errorBlock];
    }
    
    return request;
}

#pragma mark - Social auth

- (QBRequest *)logInWithFacebookSessionToken:(NSString *)sessionToken
                                  completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    QBRequest *request =
    [QBRequest logInWithSocialProvider:@"facebook"
                           accessToken:sessionToken
                     accessTokenSecret:nil
                          successBlock:^(QBResponse *response,
                                         QBUUser *tUser)
     {
         weakSelf.isAuthorized = YES;
         
         tUser.password = [QBBaseModule sharedModule].token;
         completion(response, tUser);
         
     } errorBlock:^(QBResponse *response) {
         
         [weakSelf showMessageForQBResponce:response];
         
         if (completion)
             completion(response, nil);
     }];
    
    return request;
}

@end