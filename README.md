# VolcaShare

VolcaShare is a tool to save and share settings (aka patches) for different sounds of the Korg Volca Bass and Korg Volca Keys synthesizers.  It’s basically a content management system, but instead of the content being blog posts or pictures of your feet or whatever, the content consists the parameters which define the synth patch, and therefore its sound.

## Features
📝 **Persistence**: Create, read, update, and delete patches for the Bass and Keys.  
⚡️ **Sync patches via WebMIDI**: Allows your browser to send control messages to your Volca instead of having to manually change each and every parameter.  
🔐 **Authentication**: Users can log in in order to change or delete their patches.  
🙈 **Privacy**: Registered users can keep a secret stash of patches that aren’t shared the general public.  
🔊 **Audio samples**: Users can listen to samples of synth patches on browse and detail pages and provide audio samples for their own patches.  
🎹 **Sequence support**:  VolcaShare allows users to save sequences of notes to accompany their synth patch, just like the Volcas allow you do with their built in sequencer.  
👀 **Discoverability / Ranking**: Tags can be used to categorize and navigate patches.  A sorting algoruthm based on completeness and freshness places more relevant patches higher on browse pages.  
🔀 **Patch randomization**: Change parameters randomly with the click of a button.  (Especially good mileage using th Keys with MIDI sync up.)  

## Under the hood
This application is built on these key frameworks/libraries:
* [Ruby on Rails](https://github.com/rails/rails) is the server-side MVC system.
* [MongoDB](https://www.mongodb.com/) database using [Mongoid](https://github.com/mongodb/mongoid) ODM
* HTML, CSS and Javascript ES6 makes the patch forms imitate the behavior of their physical counterparts.  Individual views are served by the Rails server (as opposed to a single page application solution).
* [Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) is used for sound in the Volca Bass Emulator
* [Bootstrap](https://github.com/twbs/bootstrap) for responsive design support and layouts.
* [Webmidi](https://github.com/djipco/webmidi) for sending MIDI signals via the browser.

## Installation
Coming soon: how to install this application on your own computer.

## Usage
Coming soon: how to *run* and use this application on your own computer.

## Reporting an issue / requesting a feature:
Please open a [GitHub issue](https://github.com/waterjump/volca-share/issues/new).

## Timeline
March 13 2016 - Repository created  
November 2016 - [VolcaShare.com](https://www.volcashare.com) launched  
January 25 2017 - Sequence support on bass patches  
August 8 2018 - Sort by quality  
February 21 2020 - [Volca Keys](https://www.volcashare.com/keys/patch/new) support  
August 15 2020 - [Volca Bass Emulator](https://www.volcashare.com/bass/emulator) launched

## License
see LICENSE.md
