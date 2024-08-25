# VolcaShare

VolcaShare is an online patch database and content management system for the Korg Volca Bass and Korg Volca Keys synthesizers.  It also syncs patches from the browser directly to the synthesizer via WebMIDI.

## Features
📝 **Persistence**: Create, read, update, and delete patches for the Bass and Keys.  
⚡️ **Sync patches via WebMIDI**: Allows your browser to send control messages to your Volca instead of having to manually change each and every parameter.  
🔐 **Authentication**: Users can log in in order to change or delete their patches.  
🙈 **Privacy**: Registered users can keep a secret stash of patches that aren’t shared the general public.  
🔊 **Audio samples**: Users can listen to samples of synth patches on browse and detail pages and provide audio samples for their own patches.  
🎹 **Sequence support**: VolcaShare allows users to save sequences of notes to accompany their synth patch, just like the Volcas allow you do with their built in sequencer.  
👀 **Discoverability / Ranking**: Tags can be used to categorize and navigate patches.  A sorting algorithm based on completeness and freshness places more relevant patches higher on browse pages.  
🔀 **Patch randomization**: Change parameters randomly with the click of a button.  (Especially good mileage using the Keys with MIDI sync up.)  
🥸 **Emulators**: Tweak knobs and make fun sounds and patterns directly in the browser, while bored at work, or on your phone on the toilet - wherever.  
&nbsp; &nbsp; &nbsp; &nbsp; **[Volca Bass Emulator](https://www.volcashare.com/bass/emulator)**:   A JavaScript implementation of a three-oscillator monosynth with a 16-step sequencer.  
&nbsp; &nbsp; &nbsp; &nbsp; **[Volca Keys Emulator](https://www.volcashare.com/keys/emulator)**:   A JavaScript implementation of a three-oscillator polysynth with a single EG and lots of ways to mess with VCO pitch.

## Under the hood
This application is built on these key frameworks/libraries:
* [Ruby on Rails](https://github.com/rails/rails) is the server-side MVC system.
* [MongoDB](https://www.mongodb.com/) database using [Mongoid](https://github.com/mongodb/mongoid) ODM.
* HTML, CSS and Javascript ES6 make the patch forms imitate the behavior of their physical counterparts.  Individual views are served by the Rails server (as opposed to a single page application solution).
* [Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) is used for sound in the Volca Bass Emulator.
* [Bootstrap](https://github.com/twbs/bootstrap) for responsive design support and layouts.
* [Webmidi](https://github.com/djipco/webmidi) for sending MIDI signals via the browser.

## Installation
#### 1. Clone the repo
`git clone git@github.com:waterjump/volca-share.git`

#### 2. Ruby version
VolcaShare currently runs on ruby 2.7.5 and uses [rbenv](https://github.com/rbenv/rbenv "rbenv") for ruby version management.
While in the project directory, run `rbenv local` to set the ruby version configured in the repo.  If you don't have this version of ruby, you can install it with `rbenv install 2.7.5`. You will also need the `bundler` gem.

#### 3. Node version
This app requires node 17.6.0 (with npm 8.5.1) and uses [nvm](https://github.com/nvm-sh/nvm "nvm") to manage node versions.

`nvm install 17.6.0`

#### 4. Install MongoDB
`brew tap mongodb/brew`

`brew install mongodb-community@5.0`

`brew services start mongodb/brew/mongodb-community`

#### 5. Setup secrets file
Make a copy of the secrets.yml.sample:

`cp config/secrets.yml.sample config/secrets.yml`

Generate values and add them to the newly generated secrets.yml file.

`RAILS_ENV=development bundle exec rake secret`

This will give you a long string of letters and numbers that can be used as the `secret_key_base` value.
Repeat for test environment as well.

#### 6. Remove RECAPTCHA stuff
It's easiest just to do a project wide search for 'recaptcha' (case insensitive) and remove all matching lines.  If you want to configure your own recaptcha account for this app, you can do this on your own.

#### 7. Install nodejs dependencies
`npm install`

#### 8. Install ruby dependencies
`bundle install`



## Usage
#### Starting the server

`bundle exec rails s`

Then visit http://127.0.0.1:3000/ in a web browser.

#### Running tests

`bundle exec rspec`


## Reporting an issue / requesting a feature:
Please open a [GitHub issue](https://github.com/waterjump/volca-share/issues/new).

## Timeline
March 13 2016 - Repository created  
November 2016 - [VolcaShare.com](https://www.volcashare.com) launched  
January 25 2017 - Sequence support on bass patches  
August 8 2018 - Sort by quality  
February 21 2020 - [Volca Keys](https://www.volcashare.com/keys/patch/new) support  
August 15 2020 - [Volca Bass Emulator](https://www.volcashare.com/bass/emulator) launched  
April 10 2022 - [Volca Bass Emulator](https://www.volcashare.com/bass/emulator) step sequencer added  

## License
see LICENSE.md
