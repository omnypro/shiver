//
//  WindowViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "AccountManager.h"
#import "TwitchAPIClient.h"
#import "User.h"

#import "UserViewModel.h"

@interface UserViewModel ()

@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSURL *logoImageURL;

@end

@implementation UserViewModel

- (instancetype)init
{
    self = [super init];
    if (self == nil) return nil;

    self.client = [TwitchAPIClient sharedClient];
    self.user = nil;

    [self initializeSignals];

    return self;
}

- (void)initializeSignals
{
    // A combined singal for whether or not the account manager is
    // both ready and reachable.
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];

    // Signals related to credential checking.
    RACSignal *credentialSignal = RACObserve(AccountManager.sharedManager, credential);
    RACSignal *hasCredential = [credentialSignal map:^(AFOAuthCredential *credential) { return @(credential != nil); }];

    // Observers.
    RAC(self, user) = [RACSignal
        combineLatest:@[readyAndReachable, hasCredential, [self.client fetchUser]]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, User *user){
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && user != nil) {
                DDLogInfo(@"Application (%@): We have a user. (%@)", [self class], user.name);
                return user;
            } else {
                DDLogInfo(@"Application (%@): We don't have a user.", [self class]);
                return nil;
            }
        }
    ];

    RAC(self, isLoggedIn, @NO) = [RACObserve(self, user)
        map:^id(id value) {
            return @(value != nil);
        }];

    RAC(self, displayName) = RACObserve(self, user.displayName);
    RAC(self, name) = RACObserve(self, user.name);
    RAC(self, email) = RACObserve(self, user.email);
    RAC(self, logoImageURL) = RACObserve(self, user.logoImageURL);
}





//- (instancetype)init {
//	self = [super init];
//	if (self == nil) return nil;
//
//	@weakify(self);
//
//	self.store = GCYGroceryStoreViewModel.allStoresViewModel;
//
//	_signInAction = [[RACSignal
//                      defer:^{
//                          return [GCYUserController.sharedUserController signIn];
//                      }]
//                     actionEnabledIf:[hasClient not]];
//
//	RAC(self, repository) = [[[RACObserve(GCYUserController.sharedUserController, client)
//                               ignore:nil]
//                              map:^(OCTClient *client) {
//                                  NSString *repositoryNWO = @(metamacro_stringify(GCY_LIST_REPOSITORY));
//
//                                  NSArray *pieces = [repositoryNWO componentsSeparatedByString:@"/"];
//                                  NSAssert(pieces.count == 2, @"Repository name should be of the form \"owner/name\", instead got: %@", repositoryNWO);
//
//                                  return [client fetchRepositoryWithName:pieces[1] owner:pieces[0]];
//                              }]
//                             switchToLatest];
//
//	RAC(self, list) = [[[RACObserve(self, repository)
//                         ignore:nil]
//                        map:^(OCTRepository *repository) {
//                            return [GCYUserController.sharedUserController.client gcy_groceryListWithRepository:repository];
//                        }]
//                       switchToLatest];
//
//	_loadItemsAction = [[[[[[RACObserve(self, list)
//                             ignore:nil]
//                            take:1]
//                           flattenMap:^(GCYGroceryList *list) {
//                               return [list.items.rac_signal map:^(GCYGroceryItem *item) {
//                                   return [[GCYGroceryItemViewModel alloc] initWithList:list item:item];
//                               }];
//                           }]
//                          collect]
//                         map:^(NSArray *items) {
//                             // FIXME: This doesn't belong here.
//                             return [items sortedArrayUsingComparator:^(GCYGroceryItemViewModel *itemA, GCYGroceryItemViewModel *itemB) {
//                                 return [itemA.item.name localizedCaseInsensitiveCompare:itemB.item.name];
//                             }];
//                         }]
//                        action];
//
//	RAC(self, allItems) = [self.loadItemsAction.results startWith:@[]];
//
//	// TODO: Should this be an action?
//	[[[[[[RACObserve(self, allItems)
//          ignore:nil]
//         map:^(NSArray *items) {
//             return [items.rac_signal flattenMap:^(GCYGroceryItemViewModel *viewModel) {
//                 @strongify(self);
//                 return [[RACObserve(viewModel, inCart)
//                          skip:1]
//                         mapReplace:viewModel];
//             }];
//         }]
//		switchToLatest]
//       map:^(GCYGroceryItemViewModel *viewModel) {
//           @strongify(self);
//
//           NSDictionary *newDict = [viewModel.item.dictionaryValue mtl_dictionaryByAddingEntriesFromDictionary:@{
//                                                                                                                 @keypath(viewModel.item, inCart): @(viewModel.inCart)
//                                                                                                                  }];
//
//           NSError *error = nil;
//           GCYGroceryItem *newItem = [viewModel.item.class modelWithDictionary:newDict error:&error];
//           if (newItem == nil) return [RACSignal error:error];
//
//           return [[GCYUserController.sharedUserController.client
//                    // TODO: Update the VM's `item` too?
//                    gcy_replaceItem:viewModel.item withItem:newItem inGroceryList:self.list]
//                   catch:^(NSError *error) {
//                       [self->_errors sendNext:error];
//                       [self.loadItemsAction execute:nil];
//
//                       return [RACSignal empty];
//                   }];
//       }]
//      concat]
//     subscribe:nil];
//
//	RAC(self, items) = [[[[RACObserve(self, allItems)
//                           deliverOn:RACScheduler.mainThreadScheduler]
//                          combineLatestWith:RACObserve(self, store)]
//                         reduceEach:^(NSArray *items, GCYGroceryStoreViewModel *store) {
//                             if (store == GCYGroceryStoreViewModel.allStoresViewModel) return [RACSignal return:items];
//
//                             // TODO: Is there a more efficient way to do this?
//                             return [[items.rac_signal
//                                      filter:^(GCYGroceryItemViewModel *viewModel) {
//                                          return [viewModel.item.stores containsObject:store.store];
//                                      }]
//                                     collect];
//                         }]
//                        switchToLatest];
//
//	RACSignal *waitForList = [[RACObserve(self, list)
//                               ignore:nil]
//                              take:1];
//
//	_switchListsAction = [[waitForList
//                           map:^(GCYGroceryList *list) {
//                               return [[GCYGroceryStoreListViewModel alloc] initWithGroceryList:list];
//                           }]
//                          action];
//
//	RACAction *editItemAction = [[RACSamplingSignalGenerator
//                                  generatorBySampling:[RACObserve(self, list) ignore:nil]
//                                  forGenerator:[RACDynamicSignalGenerator generatorWithBlock:^(RACTuple *xs) {
//        GCYGroceryItem *item = xs[0];
//        GCYGroceryList *list = xs[1];
//
//        id viewModel = [[GCYEditableGroceryItemViewModel alloc] initWithList:list item:item];
//        return [RACSignal return:viewModel];
//    }]]
//                                 action];
//
//	RAC(self, editingItem) = editItemAction.results;
//
//	_addItemAction = [[[[RACSignal
//                         return:nil]
//                        gcy_signalGenerator]
//                       postcompose:editItemAction]
//                      action];
//    
//	_removeItemAction = [[RACDynamicSignalGenerator
//                          generatorWithBlock:^(GCYGroceryItem *item) {
//                              @strongify(self);
//                              return [[waitForList
//                                       flattenMap:^(GCYGroceryList *list) {
//                                           return [GCYUserController.sharedUserController.client gcy_removeItem:item inGroceryList:list];
//                                       }]
//                                      concat:[self.loadItemsAction signalWithValue:nil]];
//                          }]
//                         action];
//	
//	RACSignal *anyItemsCrossedOff = [[[RACObserve(self, items)
//                                       ignore:nil]
//                                      map:^(NSArray *items) {
//                                          NSArray *inCartSignals = [[[items.rac_signal
//                                                                      map:^(GCYGroceryItemViewModel *viewModel) {
//                                                                          @strongify(self);
//                                                                          return RACObserve(viewModel, inCart);
//                                                                      }]
//                                                                     startWith:[RACSignal return:@NO]]
//                                                                    array];
//                                          
//                                          return [[RACSignal combineLatest:inCartSignals] or];
//                                      }]
//                                     switchToLatest];
//	
//	_doneShoppingAction = [[[[[[[[[RACObserve(self, items)
//                                   ignore:nil]
//                                  take:1]
//                                 flattenMap:^(NSArray *items) {
//                                     return items.rac_signal;
//                                 }]
//                                filter:^(GCYGroceryItemViewModel *viewModel) {
//                                    return viewModel.inCart;
//                                }]
//                               map:^(GCYGroceryItemViewModel *viewModel) {
//                                   return viewModel.item;
//                               }]
//                              map:^(GCYGroceryItem *item) {
//                                  @strongify(self);
//                                  
//                                  // TODO: Coalesce all removals into one request.
//                                  return [GCYUserController.sharedUserController.client gcy_removeItem:item inGroceryList:self.list];
//                              }]
//                             concat]
//                            concat:[self.loadItemsAction signalWithValue:nil]]
//                           actionEnabledIf:anyItemsCrossedOff];
//	
//	[[RACSignal
//      merge:@[
//              self.signInAction.errors,
//              self.loadItemsAction.errors,
//              self.addItemAction.errors,
//              self.removeItemAction.errors,
//              self.doneShoppingAction.errors,
//              ]]
//     subscribe:_errors];
//	
//	[[[[self.didBecomeActiveSignal
//		flattenMap:^(GCYGroceryListViewModel *viewModel) {
//			return [[[[viewModel.signInAction
//                       signalWithValue:nil]
//                      ignoreValues]
//                     concat:[RACSignal return:viewModel]]
//                    catchTo:[RACSignal empty]];
//		}]
//       flattenMap:^(GCYGroceryListViewModel *viewModel) {
//           return [[[viewModel.loadItemsAction
//                     signalWithValue:nil]
//                    concat:[RACSignal return:RACUnit.defaultUnit]]
//                   catchTo:[RACSignal empty]];
//       }]
//      take:1]
//     subscribe:nil];
//    
//	return self;
//}




@end
