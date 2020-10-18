# Sign Up with LinkedIn on Rails
## Intro

A few months ago I was working on a platform focused on following up and guiding innovation ventures, our client wanted to add an easy way for their users to sign up, and, considering it was focused on professionals, they decided LinkedIn was the best option.

After a lot of tutorials that broke in the middle of the process, stackoverflowing (I guess this works if Googling is a word now) weird bugs, and 16 cups of coffee I decided to write this tutorial with the hope to make someone's work easier.

I will be using the ruby gem [OmniAuth LinkedIn OAuth2](https://medium.com/r/?url=https%3A%2F%2Fgithub.com%2Fdecioferreira%2Fomniauth-linkedin-oauth2) in a Ruby on Rails application with [Devise](https://github.com/heartcombo/devise) authentication.

*Note: My actual setup is Rails 6.0.3.4 and Ruby 2.6.5*

## LinkedIn Setup
First of all, to log in with LinkedIn we first need a LinkedIn app, to get one follow these steps:
1. Go to [LinkedIn Developers](https://medium.com/r/?url=https%3A%2F%2Fwww.linkedin.com%2Fdevelopers), sign in, and click on "Create app"

*Note: This app needs to be associated with a company page, if you don't have one, create it [here](https://business.linkedin.com/es-es/marketing-solutions/linkedin-pages).*

2. Fill up the form and follow the steps to **verify** the app. You should get to this step where they ask you to send a **Verification URL** to the Page Admin you are creating the app to.

*Note: The verification process should not take more than a few minutes.*

3. Now that you have a verified App, under the **Products** tab, select "**Sign In with LinkedIn**".

4. You'll see a **"Review in progress"** message, refresh your page after a few minutes until the message disappears.

5. Go to the **"Auth"** tab to get your **Authentication keys (both Client ID and Client Secret)**, we will use them later.

6. Last but not least, we need to tell our LinkedIn application the **URL** to **redirect the user** after they successfully logged with LinkedIn. So let's update the **Authorized redirect URLs** for our app to our development URL 👉🏻http://localhost:3000/users/auth/linkedin/callback

## Rails Setup

Because we want to focus on adding [OAuth2](https://medium.com/r/?url=https%3A%2F%2Fgithub.com%2Fdecioferreira%2Fomniauth-linkedin-oauth2) to our application (and there are a billion tutorials on how to create a Rails app with **Devise** out there), we'll begin with a basic Rails template that already has the Devise setup:

`rails new --database postgresql -m https://raw.githubusercontent.com/mangotreedev/templates/master/mangoTree.rb linkedin-login`

*Note: If you want, you can create your own app from scratch and follow the setup for Devise [here](https://medium.com/r/?url=https%3A%2F%2Fgithub.com%2Fheartcombo%2Fdevise).*

## Rails Configuration

Let's start by creating a '.env' file (thanks to [dotenv](https://medium.com/r/?url=https%3A%2F%2Fgithub.com%2Fbkeepers%2Fdotenv)) and storing there our **Authentication keys**.

`touch .env`

Your '.env' file should look like this (but without the *):


`LINKEDIN_API_ID = "8************f" 
LINKEDIN_API_KEY = "n************Q"`

Second, we will add the **OmniAuth** gem into our **Gemfile**:

`gem "omniauth-linkedin-oauth2", '1.0.0'`

and bundle it

`bundle install`

Now, we need to tell **Devise** that we are going to use **OmniAuth** with LinkedIn and where to find our **Authentication keys**.

So go to your 'config/initializers/devise.rb' file and **add**:

`[...]
config.omniauth :linkedin, ENV['LINKEDIN_API_ID'], ENV['LINKEDIN_API_KEY']
[...]`

After that, let's allow our **User** model (created by Devise) to log in through **OmniAuth**, and set the provider as LinkedIn:

`class User < ApplicationRecord
   [...] 
    devise :omniauthable, omniauth_providers: %i[linkedin]
   [...]
end`

*Note: You need to add that line, don't replace the previous devise options.*

Remember the URL we told our LinkedIn app to go after we successfully login through LinkedIn? Let's prepare our application to handle that route.

Let's go to our 'config/routes.rb' file and add:

`devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }`

*Note: The 'devise_for :users' should already be there, add the controllers part only.*

This will create the next route:

`Prefix:  user_linkedin_omniauth_callback
Verb: GET|POST
URI Pattern: /users/auth/linkedin/callback(.:format)
Controller#Action: users/omniauth_callbacks#linkedin`

By default,  our User created by Devise only has the attributes email and password. That's not enough if we want to take advantage of the information provided by LinkedIn, so let's add some attributes to our users with a migration:

`rails g migration AddProviderToUsers provider uid first_name last_name picture_url`

This will create the following migration file:

`class AddProviderToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :picture_url, :string
  end
end`

Now we can run the migration:

`rails db:migrate`

So our user model has all the attributes needed, let's add two methods in our User model ('app/models/user.rb') to manage the data provided by LinkedIn:

<script src="https://gist.github.com/nicoproto/cd0016270a696dd168bffa2aa9e06750.js"></script>

*Note: The first method is redefining Device's 'new_with_session' method for our User model and the second method tries to find an existing user logged in with LinkedIn credentials (a combination of uid and provider) and if it doesn't find one, it will create a new user with the information provided by LinkedIn.*

Ok, so our User model is ready now, the next step is to create the controller that will handle the callback route we created in our app.

`mkdir app/controllers/users
touch app/controllers/users/omniauth_callbacks_controller.rb`

Now let's add the method that will be called when redirecting from LinkedIn.

<script src="https://gist.github.com/nicoproto/37f4435eab102d2d7eb1146f89494f00.js"></script>

Almost done, now it's time to test it! Let's add a simple Bootstrap navbar to see it in action:

`touch app/views/shared/_navbar.html.erb`

And add this in your '_navbar.html.erb':

<script src="https://gist.github.com/nicoproto/d652118a8f52ae0f482121f3f2bf0959.js"></script>

Don't forget to add the navbar and [Bootstrap CDN](https://medium.com/r/?url=https%3A%2F%2Fwww.bootstrapcdn.com%2F) in your 'application.html.erb' file:

<script src="https://gist.github.com/nicoproto/3f16701bdb04ea68a93f5bc06b077cee.js"></script>

And that's it! Now you can try to log in by clicking on the navbar 'login' link and then selecting the option 'Sign in with LinkedIn'.

## Optional: Edit LinkedIn user's profile without a password

Just in case you didn't notice yet, Users created through this process can't edit their profile. Why? Because they don't have a confirmation password. In case you need your users to update their first_name or last_name, let's fix that.

To accomplish this, we will need to get our hands dirty into the depths of Devise Controllers and Views. 

First, let's add the fields first_name and last_name in our 'app/views/devise/registrations/edit.html.erb' file so we can see them on our edit profile page:

<script src="https://gist.github.com/nicoproto/36f96e8e4dfd86d440a20ab928531661.js"></script>

*Note: We also added an if statement to check if the current_user has a provider, if so,  we don't show the password fields.*

Now we are going to rewrite Devise's Registration Controller, so first we are going to generate it:

`rails generate devise:controllers "" -c=registrations`

Now, we'll tell our Devise routes to use this new controller by updating our 'route.rb' file:

`devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }`

And let's replace the content of that 'registrations_controller.rb' so it looks like this:

<script src="https://gist.github.com/nicoproto/220a82b8763c7a149589c723bfeebbcf.js"></script>

*Note: Long story short, we are telling Devise that if the User that's trying to update their profile has logged through LinkedIn (their provider attribute is not blank) we should update without requesting the password.*

Finally, we need to allow the new attributes to go through the devise_parameter_sanitizer (security reasons) and we can do that by adding this to our 'application_controller.rb' file:

<script src="https://gist.github.com/nicoproto/1910568a36bdfaae6671864d77500895.js"></script>

And that's it! You are now able to update your first_name and last_name fields even if you signed up through LinkedIn.





