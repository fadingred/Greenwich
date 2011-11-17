# Greenwich

Greenwich is a framework for easily allowing users to translate Cocoa applications.

## Overview

Greenwich allows users to translate your Cocoa applications quickly and conveniently using a
simple interface that is packaged directly within the application:

![Translator](https://github.com/fadingred/Greenwich/raw/master/Documentation/translator.png)

As a translator works through the strings in your application, she can simply relaunch the
application at any time to see the changes directly in the app. This significantly improves
the feedback loop for translators and will result in better, faster translations.

Greenwich has been built both for translators and for developers. As a developer, you'll no
longer have to think about localization again. Greenwich has scripts that integrate directly
into your build process &mdash; strings will be extracted from both your xib files and your
source code as you go. Set it up once, and forget about it. Your strings files will always be
kept up to date, and Greenwich will keep you informed of any actions you need to take through
informative build warnings. Enough talk, let's get this thing set up already!

## Setup

Greenwich is quick to set up. You'll want to download one of the compiled versions from the
downloads section of Github. Once you've downloaded Greenwich, there are two main components
to the setup: the scripts and the framework.

### Scripts

The Greenwich download comes with a folder called Scripts. You'll need to copy this folder
to a location where your build will be able to find the scripts. It is generally advisable
to copy the entire folder into your project directory, but you can also put the scripts
in a shared location so multiple projects can use the same installation.

Once the scripts are copied, you need to configure your Xcode project to use the scripts.
This is as simple as adding a few _Run Script_ build phases. In your Xcode project:

  1. Click on your project in the project navigator
  1. Select on your target in the targets section
  1. Switch to the _Build Phases_ tab
  1. Click _Add Build Phase_
  1. Choose _Add Run Script_
  1. Move this build phase **above** the _Copy Bundle Resources_ build phase
  1. Update the script to `./Scripts/localization create -s. -r.`

[![Add Run Script](file:///Users/wbyoung/Code/Greenwich/Documentation/runscript_thumbnail.png)](https://github.com/fadingred/Greenwich/raw/master/Documentation/runscript.png) [![Define Run Script](file:///Users/wbyoung/Code/Greenwich/Documentation/definescript_thumbnail.png)](https://github.com/fadingred/Greenwich/raw/master/Documentation/definescript.png)

This is sufficient for Greenwich to generate strings files for you, but you can add one more piece to the puzzle.
This step is optional, but recommended. Simply add another _Run Script_ but do the following for this script:

  1. Move this build phase **below** the _Copy Bundle Resources_ build phase
  1. Update the script to `./Scripts/localization verify -s. -r.`

Note that these scripts do take a couple of options to allow you to specify where different files are located.
For most uses, you will only need to specify `-s`, the path to your source files, and `-r`, the path to your
resources.

Greenwich will only extract strings from unlocalized xib files. If you leave your xib files in the
lproj directories, they will not be handled by Greenwich. Simply move your master out of the lproj
directory if you want Greenwich to handle it. You won't need all those extra xibs any more, phew!

For an example of setting up the scripts using the `PATH` environment variable, check out
the example application included with the source code.

### Link & Copy Framework

Linking and copying the framework is similar to other Mac OS X frameworks.
Documentation for this procedure will be added shortly.


## Usage

Once you've set everything up, you're good to go. Greenwich will work with your existing calls to
`NSLocalizedString` and will translate all your xib files as they're loaded. In certain cases,
however, you may find that you need to make a few changes to the positions of UI elements after
localization has occurred. Don't worry, we've got you covered:

    - (void)awakeFromLocalization {
        // calculate the size of ui elements & reposition things
    }

If you're using your own macro based off of `NSLocalizedString`, simply define the `GREENWICH_LOCALIZATION_SYMBOL` in
your Xcode configuration with that symbol, and Greenwich will handle it from there!


## Compatibility

Greenwich is currently compatible with Cocoa applications running on Mac OS X 10.6+. We intend
to bring the framework to iOS applications, and if you're interested in helping, please let us
know!
