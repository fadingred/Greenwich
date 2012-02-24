# Greenwich

Greenwich is a framework for easily allowing users to translate Cocoa applications.

## Overview

Greenwich allows users to translate your Cocoa applications quickly and conveniently using a
simple interface that is packaged directly within the application:

![Translator](http://fadingred.github.com/greenwich/media/images/translator.png)

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
downloads section of Github. Once you've downloaded Greenwich, there are three parts
to the setup: scripts, framework, and code.

### Scripts

The Greenwich download comes with a folder called Scripts. You'll need to copy this folder
to a location where your build will be able to find the scripts. It is generally advisable
to copy the entire folder into your project directory, but you can also put the scripts
in a shared location so multiple projects can use the same installation.

Once the scripts are copied, you need to configure your Xcode project to use the scripts.
This is as simple as adding a few _Run Script_ build phases. In your Xcode project:

  1. Click on your project in the project navigator
  1. Select your target in the targets section
  1. Switch to the _Build Phases_ tab
  1. Click _Add Build Phase_
  1. Choose _Add Run Script_
  1. Move this build phase **above** the _Copy Bundle Resources_ build phase
  1. Update the script to `./Scripts/localization create -s. -r.`

[![Set Runpath Search Paths](http://fadingred.github.com/greenwich/media/images/runpaths_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/runpaths.png)
[![Add Run Script](http://fadingred.github.com/greenwich/media/images/runscript_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/runscript.png)
[![Define Run Script](http://fadingred.github.com/greenwich/media/images/definescript_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/definescript.png)

This is sufficient for Greenwich to generate strings files for you, but you can add one more piece to the puzzle.
This step is optional, but recommended. Simply add another _Run Script_ but do the following for this script:

  1. Move this build phase **below** the _Copy Bundle Resources_ build phase
  1. Update the script to `./Scripts/localization verify -s. -r.`

Note that these scripts may need to be altered slightly depending on your configuration. The path
to the script should relative to your project's `.xcodeproj` file. If you put the scripts folder in a
folder called `External`, you would need to change the beginning of the script
to `./External/Scripts/localization`. The scripts also
take a couple of options to allow you to specify where different files are located.
If your source files and xib files are located in the same directory as your
project's `.xcodeproj` file, then the options provided
in the example above are be correct. If they're in different locations, though, you'll have to alter the
arguments that are passed to the script. For most uses, you will only need to specify `-s`, the path to your
source files, and `-r`, the path to your resources. Paths relative to your project's `.xcodeproj` file are acceptable.
For example, if your source files are in a folder called
`Implemenation`, you would need to specify `-s Implementation`, and if your xib files are in a folder called
`Interface Files`, you need to specify `-r "Interface Files"`.

Greenwich will only extract strings from unlocalized xib files. If you leave your xib files in the
lproj directories, they will not be handled by Greenwich. Simply move your master out of the lproj
directory if you want Greenwich to handle it. You won't need all those extra xibs any more, phew!

For an example of setting up the scripts using the `PATH` environment variable, check out
the example application included with the source code.

### Framework (Copying & Linking)

Linking and copying the framework is similar to other Mac OS X frameworks. The distribution
includes the framework which you should copy to a location where your project can access it. Again,
it is generally advisable to copy the framework into your project directory. Once in place, there
are just a few steps to getting it added into your project:

  1. Activate the project navigator in Xcode
  1. Drag `Greenwhich.framework` into the _Frameworks_ group
  1. Xcode will display a dialog for adding files
  1. Make sure your application target is checked, then click _Finish_
  1. Click on your project in the project navigator
  1. Select on your target in the targets section
  1. Switch to the _Build Settings_ tab
  1. Set _Runpath Search Paths_ to `@executable_path/../Frameworks`
  1. Switch to the _Build Phases_ tab
  1. Click _Add Build Phase_
  1. Choose _Add Copy Files_
  1. Change the _Destination_ to _Frameworks_
  1. Drag `Greenwich.framework` from the project navigator into the copy files list

[![Drag Framework](http://fadingred.github.com/greenwich/media/images/frameworkdrag_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/frameworkdrag.png)
[![Add Framework](http://fadingred.github.com/greenwich/media/images/frameworkadd_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/frameworkadd.png)
[![Copy Framework](http://fadingred.github.com/greenwich/media/images/frameworkcopy_thumbnail.png)](http://fadingred.github.com/greenwich/media/images/frameworkcopy.png)

### Code

At this point, you still need to add a little code to your application, but this is easy:

    #import <Greenwich/Greenwich.h>
    
    @interface MyAppDelegate
    
    - (void)applicationDidFinishLaunching:(NSNotification *)notification {
    	[[FRLocalizationManager defaultLocalizationManager] installExtraHelpMenu];
    }
    
    @end

When you launch the application, you can bring up the translator by holding down option while
opening the _Help_ menu... easy peasy.


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

**Source Only:**
Setting the environment variable `GREENWICH_PSEUDO_LOCALIZE` will make Greenwich pseudo-localize your application.
It will swap out certain characters and extend your strings slightly while keeping them identifiable. This setting is
great for testing to make sure that everything is localized and that you've allowed enough space for strings
in other languages.


## Compatibility

Greenwich is currently compatible with Cocoa applications running on Mac OS X 10.6+. We intend
to bring the framework to iOS applications, and if you're interested in helping, please let us
know!


## License

Greenwich is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php). Enjoy!
