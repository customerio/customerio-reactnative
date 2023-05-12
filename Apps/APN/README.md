# Ami app

This is a sample app using [Customer.io's React Native package](https://www.npmjs.com/package/customerio-reactnative). Ami app works for both Android and iOS.

# What all features can I test with Ami app ?

Ami app gives you flexibility to test multiple features such as:

- Package initialisation
- Identify user
- Clear user identify
- Track events
- Device attributes (default & custom)
- Profile attributes (default & custom)
- Push Notifications 
- Rich Push & deep links

# What Ami app doesn't offer?

Ami app is still a work in progress and there are a list of features that aren't available in this app such as:

- Dark mode - Ami app works only in normal/light mode and doesn't support dark mode
- User login status - The app does not retain user's login status and resets itself when back button is tapped or the app is relaunched

# Getting Started

Ami app already includes all the dependencies required. To run the app locally, please follow the instructions in [our development document](docs/dev-notes/DEVELOPMENT.md) to get your development environment setup and running.

## Quick Start (Customer.io team)

You can run the following command in the terminal and it will walk you through the steps needed to be able to build the app and test in the simulator or on device.

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/customerio/amiapp-reactnative/HEAD/scripts/setup.sh)"

Or if you have cloned the repo already then you can

    cd amiapp-reactnative
    bash scripts/setup.sh

# Testing the package using app 

### Initialising the package

Package gets initialised as soon as you launch the application.

### Identify user

Before using any feature of the package, you need to identify a user. 
- Tap on **Let's get started** button on the first screen, you will be taken to the next screen.
- Enter Email Id & User name 
- Tap on **Identify User** button to identify the user.

## Track Event

The app provides you four ways to test event tracking. Though the values are hard coded but this still helps you test multiple scenarios such as :

- **Any event** - Sends Button Click event 
- **Event with data** - Triggers an event with following data
```
{
    clicked : type,
    name : "Super Ami",
    country : "USA",
    city : "New York",
}
```
- **Shopping** - This button will send a Shopping event with a nested data such as:
```
{
    clicked : type,
    product : "Clothing",
    price : "USD 99",
    brand : "Trends",
    detail : {
        color : "Orange",
        size : 30,
        length : 34,
        isNew : true
    }
}
```
- **Charity Event** - Triggers and event with event type Charity and additional data as:
```
{
    clicked : type,
    org : "Percent Pledge",
    amount : "USD 500",
    to : "Urban Trees",
    verified : false
}
```

### Device attributes

To send default custom device attributes, simply tap on **Send device attributes** button. This will send following additional attributes :
```
{
    type : "Device attributes",
    detail : {
        location : "SomeLocation",
        model : "iPhone 13",
        os : "iOS 14",
    }
}
```

You can also enter some values in **Want to send some custom attributes? Type here** and **Want to add some more?** fields to send additional custom attributes. For example, if you type *Testing device attributes* and *Success* respectively, then you can see these values in your workspace as :
```
{
    type : "Device attributes",
    detail : {
        location : "SomeLocation",
        model : "iPhone 13",
        os : "iOS 14",
    },
    user_attributes : "Testing device attributes",
    additional_attributes : "Success"
}
```
Note - Fields under device attributes are optional.

### Profile attributes

Ami app also allows you flexibility to test Profile attributes. To send default static Profile attributes, tap on **Send profile attributes**.
Just like, device attributes you can send custom profile attributes by entering value of your choice in the fields under Profile attributes section.
```
{
    type : "Profile attributes",
    favouriteFood : "Pizza",
    favouriteDrink : "Mango Shake",
    customProfileAttributes: "Your custom profile attributes 1",
    additionalAttributes : "Your custom profile attributes 2"
}
```

### Clear user identify
Tap on **Clear Identity** button to clear the current user's session.

### Push Notifications & Deep link
To receive a push notification, identify (create) a user with word 'ami' in the first name. Note that you need to be a [customer.io](https://customer.io/) developer/tester to receive a notification. 

On tapping the push notification, you will be taken to the second screen i.e. to identify a user.

# Contributing

Thanks for taking an interest in our project! We welcome your contributions. Check out [our development instructions](docs/dev-notes/DEVELOPMENT.md) to get your environment set up and start contributing.

> **Note:**
> We value an open, welcoming, diverse, inclusive, and healthy community for this project. We expect all  contributors to follow our [code of conduct](https://github.com/customerio/mobile/blob/HEAD/CODE_OF_CONDUCT.md).  

# License

[MIT](LICENSE)
