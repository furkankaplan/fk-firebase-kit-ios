# FKFirebaseKit - a Firebase iOS SDK Wrapper

**FKFirebaseKit** is an opensource framework simplifying **Firebase iOS SDK**'s boilerplate code usage and its documentation. It's totally built on the Firebase iOS SDK and wraps it for you by aiming to **boost your productivity and  improve code quality** to let you focus on the real valuable part of your iOS app.

  - Simple methods with internal Error Handling.
  - Grouping methods for redability/usability as GET, SET, UPDATE, DELETE and LIST.
  - Internal logger to track request and response easily in hard-to-read Xcode log trace window.
  - Easy-to-use Authentication with Phone feature provided by Firebase.

# Why to use FKFirebaseKit instead Firebase iOS SDK?

FKFirebaseKit's API is redesigned for developer friendly usage. If you want to create a page listening and listing the user list, it's super easy with FKFirebaseKit.

<img src="https://github.com/furkankaplan/fk-firebase-kit-ios/blob/v0.1.0/fk-firebase-kit-ios/Screenshot/user-list.png">

Do you want to make an app having phone authentication with OTP? Lets look at that Interaction layer of an example VIPER module for both FKFirebaseKit and Firebase iOS SDK code comparison.

<img src="https://github.com/furkankaplan/fk-firebase-kit-ios/blob/v0.1.0/fk-firebase-kit-ios/Screenshot/send-otp.png">
<img src="https://github.com/furkankaplan/fk-firebase-kit-ios/blob/v0.1.0/fk-firebase-kit-ios/Screenshot/otp-verify.png">

FKFirebaseKit handles the filtering as human-readable. Just look at that code block comparison filtering phones with a match case. You can replace .equal with .prefix to get all phones starting with the prefix wanted.

<img src="https://github.com/furkankaplan/fk-firebase-kit-ios/blob/v0.1.0/fk-firebase-kit-ios/Screenshot/equal-match.png">

# Installation

FKFirebaseKit SDK **requires iOS 11 and newer** to run.

```
pod 'FKFirebaseKit'
```

...or for spesific version

```
pod 'FKFirebaseKit',  '~> 0.1.0'
```

# Usage

### Endpoint

You can see an endpoint argument in that all types of request methods given below. Endpoint is the exact child path that we want to send request. It's an String of Array. You can add all children to the String of Array with the same order in the Firebase Realtime Database structure.

Assume you have a database scheme and want to update the user's informations whose key is "1dsa-1dsa-adas".

```
{
  "Users" : {
    "1dsa-1dsa-adas" : {
      "createdAt" : "2020-06-18T09:55:39Z",
      "password" : "aaa",
      "phone" : "+445121231122"
    },
    "oajsd-ofc-2131" : {
      "createdAt" : "2020-06-18T10:00:45Z",
      "password" : "112233",
      "phone" : "+91000000000"
    },
    "os4bBojJPogdSvtQerydnBN6Leg2" : {
      "createdAt" : "2020-06-18T08:25:51Z",
      "password" : "1234",
      "phone" : "\"+1444444444"
    }
  }
}
```

In that case, your endpoint must be ["Users", "1dsa-1dsa-adas"]

### Set Request
You can save any data which must implement Codable easily. As a default, childByAutoId is false and it's required if you save your objects under a unique key created by Firebase. If childByAutoId is not need, just ignore and don't pass to the method.

```
let modelForSaving = UserModel(phone: "+4400000000", password: "G0asxıf1", createdAt: Date())
FKFirebaseKitManager.shared.request(set: modelForSaving, endpoint: ["Users"], childByAutoId: true) {
    print("Success")
} onError: { (message: String) in
    print(message)
}
```

### Get Request
There are two types of get request. They are listen and once. Listen type of get requests return the response to user and continue to listen the remote database if data being listened is changed. If any change occurs in realtime database, the method is triggered.

```
var observer = FKFirebaseKitManager.shared.request(get: .listen, endpoint: ["Users"]) { (response: [ResponseModel<UserModel>]) in
    for item in response {
        print(item.key)
        print(item.result)
    }
} onError: { (message: String) in
    print(message)
}
```
Get method with listen type has a return value as UInt. This UInt is created by Firebase to point observer. So If the method above is not required anymore, for example you push another ViewController, or you don't care if remote data is changed or not, just remove the observer reference. You must pass the same endpoint used in the above method to remove observer correctly.

```
FKFirebaseKitManager.shared.remove(observer: observer, for: ["Users"])
```

Another get request type is the method only called once. Here an example. Default get request is type of .once. So don't need to specify get: parametere as .once and you can ignore it.
```
FKFirebaseKitManager.shared.request(endpoint: ["Users"]) { (response: [ResponseModel<UserModel>]) in
    for item in response {
        print(item.key)
        print(item.result)
    }
} onError: { (message: String) in
    print(message)
}
```

### Update Request
Assume you have a profile page for an app and just want to update an information of a user. Just jump the related user in the realtime database structure with Users > AUTO_CHILD_KEY_OF_THE_USER path and update the object.

```
let modelForUpdating = UserModel(phone: "+4400000000", email: "furkankaplan@outlook.com", updatedAt: Date())
FKFirebaseKitManager.shared.request(update: modelForUpdating, endpoint: ["Users", AUTO_CHILD_KEY_OF_THE_USER]) {
    print("Updated user data.")
} onError: { (message: String) in
    print(message)
}
```

### Delete Request
It is enough to just jump the related child to remove data.

```
FKFirebaseKitManager.shared.request(delete: ["Users", AUTO_CHILD_KEY_OF_THE_USER]) {
    print("Account of the user removed.")
} onError: { (message: String) in
    print(message)
}
```

### Listen Request
There are 4 types of listenChild request. They are .added, .changed, .removed, .moved. Both of them listes the childs with event type. So the request type returns a observer key as UInt. The management of the observer key must be tracked in application lifecycle like described in Get Request.

Just get each user records newly added by listening the remote database.
```
FKFirebaseKitManager.shared.listenChild(forChild: .changed, endpoint: ["Users"]) { (response: [ResponseModel<UserModel>]) in
    // Do whatever you want with up-to-date data.
    // For example, update the table view.
} onError: { (message: String) in
    print(message)
}
```

### List Request
There are 5 types of filtering queries that .prefix, .starting, .ending, .equal, .between. You can use that filter methods by specifying the key that will be filtered.
```
FKFirebaseKitManager.shared.list(key: "age", filterBy: .between(22, 25), endpoint: ["Users"]) { (response: [ResponseModel<UserModel>]) in
    // Parse user datas whose ages between 22 and 25
} onError: { (message: String) in
    print(message)
}
 ```
 .. or
 ```
FKFirebaseKitManager.shared.list(key: "creditCard", filterBy: .prefix("3512"), endpoint: ["Users"]) { (response: [ResponseModel<UserModel>]) in
    // Get all users whose credit card numbers starts with 3512.
} onError: { (message: String) in
    print(message)
}
```

### Authentication with Phone
FKFirebaseKit is only supporting authentication with phone option by v0.1.0. Other options like email, sign in with Apple and other social login authorizations will be supported in the v1.0. You can review Backlog chapter.

Sending OTP with phone number.
```
FKAuthenticationManager.shared.languageCode = "tr"
FKAuthenticationManager.shared.phoneCode = "+90"

FKAuthenticationManager.shared.verify(phoneNumber: phone) {
    self.presenter?.verifyOTP()
} onError: { (message :String) in
    print("Error: \(message)")
}
```

Verifying OTP sent to user. Just input the OTP code from UITextField and pass to the verify method.

```
FKAuthenticationManager.shared.verify(otp: code) {
    print("Registered successfully")
    self.presenter?.otpVerified()
} onError: { (message: String) in
    print("Error: \(message)")
}
```

Here another authentication method check and get current user informations.

```
print("isLoggedIn: \(FKAuthenticationManager.shared.isLoggedIn)")
print("currentUser: \(FKAuthenticationManager.shared.currentUser?.phoneNumber)")
print("logout: \(FKAuthenticationManager.shared.logout())")
print("isLoggedIn: \(FKAuthenticationManager.shared.isLoggedIn)")
```

Possible output of the print group given above.

```
isLoggedIn: true
currentUser: Optional("+4400000000")
isLoggedIn: false
```

# Backlog

  - Implementation of Cloude Firestore.
  - Expanding authentication options.
  - Better log trace.
  - Limit queries with a number in order to last or first.
  - Your valuable issues and pull-requests

# Development

Want to contribute? Great! 🍺 <br>
Any issue, fork, star, pull-request is appreciated. 🚀

# Dependency
  - Firebase iOS SDK with v7.1.0

# Resource

If you want to view official annoucement about the Firebase iOS SDK and read the documentation just briefed above,

| Topic | Link |
| ------ | ------ |
| Setup | https://firebase.google.com/docs/database/ios/start |
| Release Notes | https://firebase.google.com/support/release-notes/ios |
| Recommended Data Structure | https://firebase.google.com/docs/database/ios/structure-data |
| CRUD | https://firebase.google.com/docs/database/ios/read-and-write |
| List Processes | https://firebase.google.com/docs/database/ios/lists-of-data |

# Author
  - **Furkan Kaplan** https://github.com/furkankaplan
  - Twitter : [@kaplanfurkan07](https://twitter.com/kaplanfurkan07)
  - LinkedIn : [@furkankaplan07](https://www.linkedin.com/in/furkankaplan07/)
  - Email : **furkankaplan@outlook.com**
